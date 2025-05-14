import 'package:flutter/material.dart';
import '../models/location_summary.dart';
import 'package:intl/intl.dart';

class LocationSummaryCard extends StatelessWidget {
  final LocationSummary summary;

  const LocationSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    // Format duration as hours, minutes and seconds
    final hours = summary.timeSpent.inHours;
    final minutes = summary.timeSpent.inMinutes % 60;
    final seconds = summary.timeSpent.inSeconds % 60;
    final timeString = '$hours h $minutes min $seconds sec';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    summary.locationName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    timeString,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${DateFormat('MMM dd, yyyy').format(summary.date)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
