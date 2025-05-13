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
  }

  // Stop tracking
  Future<void> stopTracking() async {
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

    return true;
  }
}

// Background service entry point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final DatabaseHelper dbHelper = DatabaseHelper();

  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  // Periodic location tracking
  Timer.periodic(const Duration(minutes: 2), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          final currentLocation = LatLng(position.latitude, position.longitude);

          // Check if inside any geofence
          final geofences = await dbHelper.getGeofences();
          String? locationName;

          for (var geofence in geofences) {
            if (geofence.isInside(currentLocation)) {
              locationName = geofence.name;
              break;
            }
          }

          // Store location record
          final locationRecord = LocationRecord(
            location: currentLocation,
            timestamp: DateTime.now(),
            locationName: locationName,
            isClockIn: false, // Not a clock in/out event
          );

          await dbHelper.insertLocationRecord(locationRecord);

          // Update notification
          service.setForegroundNotificationInfo(
            title: "Location Tracking Active",
            content:
                locationName != null
                    ? "You are at $locationName"
                    : "Tracking your location...",
          );
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
