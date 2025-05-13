import 'package:latlong2/latlong.dart';

class LocationRecord {
  final int? id;
  final LatLng location;
  final DateTime timestamp;
  final String? locationName;
  final bool isClockIn;

  LocationRecord({
    this.id,
    required this.location,
    required this.timestamp,
    this.locationName,
    required this.isClockIn,
  });

  factory LocationRecord.fromMap(Map<String, dynamic> map) {
    return LocationRecord(
      id: map['id'],
      location: LatLng(map['latitude'], map['longitude']),
      timestamp: DateTime.parse(map['timestamp']),
      locationName: map['locationName'],
      isClockIn: map['isClockIn'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'timestamp': timestamp.toIso8601String(),
      'locationName': locationName,
      'isClockIn': isClockIn ? 1 : 0,
    };
  }
}
