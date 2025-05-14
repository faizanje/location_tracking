import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_record.dart';
import '../models/geofence.dart';
import 'database_helper.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:io';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final service = FlutterBackgroundService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  StreamSubscription<Position>? _positionStreamSubscription;
  final _locationUpdateController = StreamController<LatLng>.broadcast();
  Stream<LatLng> get locationUpdates => _locationUpdateController.stream;

  // Initialize the service
  Future<void> initializeService() async {
    await _checkLocationPermission();

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'location_tracking_channel',
              'Location Tracking Service',
              description:
                  'This channel is used for location tracking service notifications.',
              importance: Importance.high,
            ),
          );
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'location_tracking_channel',
        initialNotificationTitle: 'Location Tracking',
        initialNotificationContent: 'Tracking your location...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onBackgroundIos,
      ),
    );
  }

  // Start tracking
  Future<void> startTracking() async {
    await service.startService();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTracking', true);
    await prefs.setString('lastUpdateTime', DateTime.now().toIso8601String());

    // Store clock-in record
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final locationRecord = LocationRecord(
      location: LatLng(position.latitude, position.longitude),
      timestamp: DateTime.now(),
      isClockIn: true,
    );

    await _dbHelper.insertLocationRecord(locationRecord);

    // Start the position stream subscription
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update when device moves 10 meters
    );

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_handlePositionUpdate);

    print(
      'LOCATION TRACKING: Started tracking at ${position.latitude}, ${position.longitude} (${DateTime.now().toString()})',
    );
  }

  // Stop tracking
  Future<void> stopTracking() async {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    service.invoke("stopService");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTracking', false);

    // Store clock-out record
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final locationRecord = LocationRecord(
      location: LatLng(position.latitude, position.longitude),
      timestamp: DateTime.now(),
      isClockIn: false,
    );

    await _dbHelper.insertLocationRecord(locationRecord);
    print(
      'LOCATION TRACKING: Stopped tracking at ${position.latitude}, ${position.longitude} (${DateTime.now().toString()})',
    );
  }

  // Check if tracking is active
  Future<bool> isTracking() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isTracking') ?? false;
  }

  // Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // Request background permission on Android 10+ (API 29+)
    if (Platform.isAndroid) {
      final backgroundPermission = await Geolocator.checkPermission();
      if (backgroundPermission == LocationPermission.denied ||
          backgroundPermission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }
    }

    return true;
  }

  // Add method to handle position updates
  void _handlePositionUpdate(Position position) async {
    final currentLocation = LatLng(position.latitude, position.longitude);
    final now = DateTime.now();

    print("LOCATION TRACKING: Position updated to ${position.latitude}, ${position.longitude} (${now.toString()})");
    // Check if inside any geofence
    final geofences = await _dbHelper.getGeofences();
    List<String> currentGeofences = [];

    for (var geofence in geofences) {
      print("LOCATION TRACKING: Checking geofence ${geofence.name} at ${geofence.center.latitude}, ${geofence.center.longitude} with radius ${geofence.radius}");
      if (geofence.isInside(currentLocation)) {
        print("LOCATION TRACKING: Inside geofence ${geofence.name} at ${geofence.center.latitude}, ${geofence.center.longitude} with radius ${geofence.radius}");
        currentGeofences.add(geofence.name);
      }
    }

    // Store time in geofences or as traveling time
    if (currentGeofences.isNotEmpty) {
      for (String geofenceName in currentGeofences) {
        // Store location record for each geofence
        final locationRecord = LocationRecord(
          location: currentLocation,
          timestamp: now,
          locationName: geofenceName,
          isClockIn: false, // Not a clock in/out event
        );
        await _dbHelper.insertLocationRecord(locationRecord);

        print(
          'LOCATION TRACKING: Saved location in geofence "$geofenceName" at ${position.latitude}, ${position.longitude} (${now.toString()})',
        );
      }
    } else {
      // Traveling (not in any geofence)
      final locationRecord = LocationRecord(
        location: currentLocation,
        timestamp: now,
        locationName: "Traveling",
        isClockIn: false,
      );
      await _dbHelper.insertLocationRecord(locationRecord);

      print(
        'LOCATION TRACKING: Saved traveling location at ${position.latitude}, ${position.longitude} (${now.toString()})',
      );
    }

    // Broadcast location update (optional - see below)
    _locationUpdateController.add(currentLocation);
  }

  void dispose() {
    _positionStreamSubscription?.cancel();
    _locationUpdateController.close();
  }
}

// Background service entry point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final DatabaseHelper dbHelper = DatabaseHelper();
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  // Periodic location tracking (every 2 minutes)
  Timer.periodic(const Duration(minutes: 2), (timer) async {
    if (!(await prefs.getBool('isTracking') ?? false)) {
      return; // Don't track if not supposed to be tracking
    }

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          final currentLocation = LatLng(position.latitude, position.longitude);
          final now = DateTime.now();

          // Get last update time from SharedPreferences
          final lastUpdateTimeStr = prefs.getString('lastUpdateTime');
          final lastUpdateTime =
              lastUpdateTimeStr != null
                  ? DateTime.parse(lastUpdateTimeStr)
                  : now.subtract(
                    const Duration(minutes: 2),
                  ); // Default to 2 minutes ago

          // Calculate time elapsed since last update
          final timeDelta = now.difference(lastUpdateTime);

          // Check if inside any geofence
          final geofences = await dbHelper.getGeofences();
          List<String> currentGeofences = [];

          for (var geofence in geofences) {
            if (geofence.isInside(currentLocation)) {
              currentGeofences.add(geofence.name);
            }
          }

          // Store time in geofences or as traveling time
          if (currentGeofences.isNotEmpty) {
            for (String geofenceName in currentGeofences) {
              // Store location record for each geofence
              final locationRecord = LocationRecord(
                location: currentLocation,
                timestamp: now,
                locationName: geofenceName,
                isClockIn: false, // Not a clock in/out event
              );
              await dbHelper.insertLocationRecord(locationRecord);

              // Add debug print statement
              print(
                'LOCATION TRACKING: Saved location in geofence "$geofenceName" at ${position.latitude}, ${position.longitude} (${now.toString()})',
              );
            }

            // Update notification showing all geofences
            service.setForegroundNotificationInfo(
              title: "Location Tracking Active",
              content: "You are at ${currentGeofences.join(', ')}",
            );
          } else {
            // Traveling (not in any geofence)
            final locationRecord = LocationRecord(
              location: currentLocation,
              timestamp: now,
              locationName: "Traveling",
              isClockIn: false,
            );
            await dbHelper.insertLocationRecord(locationRecord);

            // Add debug print statement
            print(
              'LOCATION TRACKING: Saved traveling location at ${position.latitude}, ${position.longitude} (${now.toString()})',
            );

            // Update notification
            service.setForegroundNotificationInfo(
              title: "Location Tracking Active",
              content: "Traveling",
            );
          }

          // Update last update time
          await prefs.setString('lastUpdateTime', now.toIso8601String());
        } catch (e) {
          print('Error getting location: $e');
        }
      }
    }
  });
}

// Required for iOS
@pragma('vm:entry-point')
Future<bool> onBackgroundIos(ServiceInstance service) async {
  return true;
}
