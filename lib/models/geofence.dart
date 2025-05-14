import 'package:latlong2/latlong.dart';

class Geofence {
  final int? id;
  final String name;
  final LatLng center;
  final double radius; // in meters
  final String? description;

  Geofence({
    this.id,
    required this.name,
    required this.center,
    this.radius = 50.0, // Default radius of 50 meters
    this.description,
  });

  factory Geofence.fromMap(Map<String, dynamic> map) {
    return Geofence(
      id: map['id'],
      name: map['name'],
      center: LatLng(map['latitude'], map['longitude']),
      radius: map['radius'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': center.latitude,
      'longitude': center.longitude,
      'radius': radius,
      'description': description,
    };
  }

  bool isInside(LatLng point) {
    final Distance distance = const Distance();
    final double calculatedDistance = distance.as(
      LengthUnit.Meter,
      center,
      point,
    );
    print("Distance from center: $calculatedDistance meters");
    return calculatedDistance <= radius;
  }
}
