import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../models/geofence.dart';
import '../../components/add_geofence_button.dart';

class GeofenceScreen extends StatelessWidget {
  const GeofenceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Geofences'), elevation: 0),
      body: Consumer<LocationProvider>(
        builder: (context, provider, child) {
          final geofences = provider.geofences;

          return geofences.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No geofences defined yet.\nAdd your first geofence!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: geofences.length,
                itemBuilder: (context, index) {
                  final geofence = geofences[index];
                  return Dismissible(
                    key: Key(geofence.id.toString()),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: Text(
                                'Delete geofence "${geofence.name}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                      );
                    },
                    onDismissed: (direction) {
                      provider.deleteGeofence(geofence.id!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Deleted ${geofence.name}')),
                      );
                    },
                    child: ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(geofence.name),
                      subtitle: Text(
                        geofence.description ??
                            'Radius: ${geofence.radius.toStringAsFixed(1)}m',
                      ),
                      trailing: Text(
                        '${geofence.radius.toStringAsFixed(0)}m',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              );
        },
      ),
      floatingActionButton: const AddGeofenceButton(),
    );
  }
}
