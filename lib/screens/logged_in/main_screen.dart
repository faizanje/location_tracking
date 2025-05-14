import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/clock_button.dart';
import '../../providers/location_provider.dart';
import 'summary_screen.dart';
import 'geofence_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final isTracking = locationProvider.isTracking;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracker'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SummaryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.place),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GeofenceScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, size: 100, color: Colors.blue),
            const SizedBox(height: 32),
            Text(
              isTracking ? 'Tracking Active' : 'Tracking Inactive',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isTracking ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isTracking
                  ? 'Your location is being tracked in the background'
                  : 'Press Clock In to start tracking your location',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            ClockButton(
              isClockIn: !isTracking,
              isActive: true,
              onPressed: () async {
                if (isTracking) {
                  await locationProvider.stopTracking();
                } else {
                  await locationProvider.startTracking();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
