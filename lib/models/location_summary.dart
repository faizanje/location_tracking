class LocationSummary {
  final String locationName;
  final Duration timeSpent;
  final DateTime date;

  LocationSummary({
    required this.locationName,
    required this.timeSpent,
    required this.date,
  });

  factory LocationSummary.fromMap(Map<String, dynamic> map) {
    return LocationSummary(
      locationName: map['locationName'],
      timeSpent: Duration(milliseconds: map['timeSpentMillis']),
      date: DateTime.parse(map['date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'locationName': locationName,
      'timeSpentMillis': timeSpent.inMilliseconds,
      'date': date.toIso8601String(),
    };
  }
}
