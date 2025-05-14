import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';

class AddGeofenceButton extends StatelessWidget {
  const AddGeofenceButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showAddGeofenceDialog(context),
      child: const Icon(Icons.add_location),
    );
  }

  void _showAddGeofenceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final radiusController = TextEditingController(text: '50.0');

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Add Current Location as Geofence'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Home, Office, etc.',
                    ),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                    ),
                  ),
                  TextField(
                    controller: radiusController,
                    decoration: const InputDecoration(
                      labelText: 'Radius (meters)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Name is required')),
                    );
                    return;
                  }

                  final description = descriptionController.text.trim();
                  double radius = 50.0;
                  try {
                    radius = double.parse(radiusController.text);
                    if (radius <= 0) {
                      throw FormatException('Radius must be positive');
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid radius'),
                      ),
                    );
                    return;
                  }

                  // Add geofence at current location
                  final locationProvider = Provider.of<LocationProvider>(
                    context,
                    listen: false,
                  );
                  locationProvider
                      .addGeofenceAtCurrentLocation(
                        name,
                        description: description.isEmpty ? null : description,
                        radius: radius,
                      )
                      .then((success) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Geofence "$name" added')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to get current location'),
                            ),
                          );
                        }
                      });

                  Navigator.of(ctx).pop();
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }
}
