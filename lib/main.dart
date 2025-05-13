import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/location_provider.dart';
import 'screens/logged_in/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the location provider
  final locationProvider = LocationProvider();
  await locationProvider.initialize();

  runApp(MyApp(locationProvider: locationProvider));
}

class MyApp extends StatelessWidget {
  final LocationProvider locationProvider;

  const MyApp({super.key, required this.locationProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: locationProvider,
      child: MaterialApp(
        title: 'Location Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}
