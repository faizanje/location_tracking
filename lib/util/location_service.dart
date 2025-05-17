import 'package:background_location/background_location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_record.dart';
import '../models/geofence.dart';
import 'database_helper.dart';
import 'dart:async';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _locationController = StreamController<LatLng>.broadcast();
  Stream<LatLng> get locationUpdates => _locationController.stream;

  // Initialize permissions and setup
  Future<void> initializeService() async {
    // Setup Android notification
    await BackgroundLocation.setAndroidNotification(
      title: "Location Tracking",
      message: "Tracking your location...",
      icon: "@mipmap/ic_launcher",
    );

    // Set location update interval (1 second)
    await BackgroundLocation.setAndroidConfiguration(1000);
  }

  // Start tracking location
  Future<void> startTracking() async {
    // Stop any previously running service
    await BackgroundLocation.stopLocationService();

    // Start location service with 10m distance filter
    await BackgroundLocation.startLocationService(distanceFilter: 10);

    // Listen for location updates
    BackgroundLocation.getLocationUpdates((location) {
      _processLocationUpdate(location);
    });

    // Save tracking state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTracking', true);

    // Record clock-in
    await _recordClockInOut(true);
  }

  // Stop tracking location
  Future<void> stopTracking() async {
    await BackgroundLocation.stopLocationService();

    // Save tracking state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTracking', false);

    // Record clock-out
    await _recordClockInOut(false);
  }

  // Record clock in/out event
  Future<void> _recordClockInOut(bool isClockIn) async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final locationRecord = LocationRecord(
      location: LatLng(position.latitude, position.longitude),
      timestamp: DateTime.now(),
      isClockIn: isClockIn,
    );

    await _dbHelper.insertLocationRecord(locationRecord);
  }

  // Check if tracking is currently active
  Future<bool> isTracking() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isTracking') ?? false;
  }

  // Process each location update
  void _processLocationUpdate(location) async {
    final currentLocation = LatLng(location.latitude, location.longitude);
    final now = DateTime.now();

    // Get all geofences
    final geofences = await _dbHelper.getGeofences();
    List<String> currentGeofences = [];

    // Check if inside any geofence
    for (var geofence in geofences) {
      // Use geolocator's distanceBetween as required
      final distance = Geolocator.distanceBetween(
        geofence.center.latitude,
        geofence.center.longitude,
        currentLocation.latitude,
        currentLocation.longitude,
      );

      if (distance <= geofence.radius) {
        currentGeofences.add(geofence.name);
      }
    }

    // Save location record
    if (currentGeofences.isNotEmpty) {
      for (var name in currentGeofences) {
        await _dbHelper.insertLocationRecord(
          LocationRecord(
            location: currentLocation,
            timestamp: now,
            locationName: name,
            isClockIn: false,
          ),
        );
      }
    } else {
      await _dbHelper.insertLocationRecord(
        LocationRecord(
          location: currentLocation,
          timestamp: now,
          locationName: "Traveling",
          isClockIn: false,
        ),
      );
    }

    // Notify listeners
    _locationController.add(currentLocation);
  }

  void dispose() {
    _locationController.close();
  }
}
