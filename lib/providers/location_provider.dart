import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_record.dart';
import '../models/location_summary.dart';
import '../models/geofence.dart';
import '../util/database_helper.dart';
import '../util/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isTracking = false;
  List<LocationRecord> _locationRecords = [];
  List<Geofence> _geofences = [];
  LatLng? _currentLocation;

  // Getters
  bool get isTracking => _isTracking;

  List<LocationRecord> get locationRecords => _locationRecords;

  List<Geofence> get geofences => _geofences;

  LatLng? get currentLocation => _currentLocation;

  // Initialize the provider
  Future<void> initialize() async {
    // Initialize location service
    await _locationService.initializeService();

    // Check if tracking is active
    _isTracking = await _locationService.isTracking();

    // Load geofences
    _geofences = await _dbHelper.getGeofences();

    // If no geofences exist, add some sample geofences
    if (_geofences.isEmpty) {
      await _addSampleGeofences();
      _geofences = await _dbHelper.getGeofences();
    }

    // Update current location
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current location: $e');
    }

    // Listen for location updates
    _locationService.locationUpdates.listen((location) {
      _currentLocation = location;
      notifyListeners();
    });

    notifyListeners();
  }

  // Start tracking location
  Future<void> startTracking() async {
    await _locationService.startTracking();
    _isTracking = true;
    notifyListeners();
  }

  // Stop tracking location
  Future<void> stopTracking() async {
    await _locationService.stopTracking();
    _isTracking = false;
    notifyListeners();
  }

  // Get current location
  Future<LatLng?> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentLocation = LatLng(position.latitude, position.longitude);
      notifyListeners();
      return _currentLocation;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Add geofence at current location
  Future<bool> addGeofenceAtCurrentLocation(
    String name, {
    String? description,
    double radius = 50.0,
  }) async {
    final currentLocation = await getCurrentLocation();
    if (currentLocation == null) {
      return false;
    }

    final geofence = Geofence(
      name: name,
      center: currentLocation,
      radius: radius,
      description: description,
    );

    await addGeofence(geofence);
    return true;
  }

  // Get location records for a specific day
  Future<List<LocationRecord>> getLocationRecordsForDay(DateTime date) async {
    _locationRecords = await _dbHelper.getLocationRecordsForDay(date);
    notifyListeners();
    return _locationRecords;
  }

  // Calculate the time spent summary for a specific day
  Future<List<LocationSummary>> getLocationSummary(DateTime date) async {
    // Get all location records for the day
    final records = await _dbHelper.getLocationRecordsForDay(date);

    if (records.isEmpty) {
      return [];
    }

    // Group records by location name
    final Map<String, List<LocationRecord>> locationGroups = {};

    for (var record in records) {
      final locationName = record.locationName ?? 'Traveling';
      if (!locationGroups.containsKey(locationName)) {
        locationGroups[locationName] = [];
      }
      locationGroups[locationName]!.add(record);
    }

    // Calculate time spent at each location
    final List<LocationSummary> summaries = [];

    for (var locationName in locationGroups.keys) {
      final records = locationGroups[locationName]!;
      records.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      Duration totalTime = Duration.zero;

      // Calculate time between consecutive records
      for (var i = 0; i < records.length - 1; i++) {
        final current = records[i];
        final next = records[i + 1];

        // If this is a clock-out record or next is a clock-in record, skip
        if (!current.isClockIn && next.isClockIn) continue;

        final difference = next.timestamp.difference(current.timestamp);
        totalTime += difference;
      }

      summaries.add(
        LocationSummary(
          locationName: locationName,
          timeSpent: totalTime,
          date: date,
        ),
      );
    }

    return summaries;
  }

  // Add a new geofence
  Future<void> addGeofence(Geofence geofence) async {
    await _dbHelper.insertGeofence(geofence);
    _geofences = await _dbHelper.getGeofences();
    notifyListeners();
  }

  // Update an existing geofence
  Future<void> updateGeofence(Geofence geofence) async {
    await _dbHelper.updateGeofence(geofence);
    _geofences = await _dbHelper.getGeofences();
    notifyListeners();
  }

  // Delete a geofence
  Future<void> deleteGeofence(int id) async {
    await _dbHelper.deleteGeofence(id);
    _geofences = await _dbHelper.getGeofences();
    notifyListeners();
  }

  // Add sample geofences for testing
  Future<void> _addSampleGeofences() async {
    // Sample locations as specified in requirements
    final geofences = [
      Geofence(
        name: 'Home',
        center: LatLng(37.7749, -122.4194),
        radius: 50,
        description: 'Home Location',
      ),
      Geofence(
        name: 'Office',
        center: LatLng(37.7858, -122.4364),
        radius: 50,
        description: 'Office Location',
      ),
    ];

    for (var geofence in geofences) {
      await _dbHelper.insertGeofence(geofence);
    }
  }
}
