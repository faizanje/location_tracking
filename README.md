# Location Tracking App

A Flutter application that tracks a user's live location and provides summaries of time spent in predefined locations.

## Features

- **Location Tracking**: Monitors the user's location in the background, even when the app is minimized
- **Geofence Management**: Tracks time spent within predefined locations (each defined as a point with a 50m radius)
- **Daily Summaries**: View time spent in each location on a daily basis
- **Simple Interface**: Easy-to-use UI with "Clock In" and "Clock Out" functionality

## Screens

### Main Screen
- Features "Clock In" and "Clock Out" buttons to start/stop location tracking
- Shows current tracking status

### Summary Screen
- Displays a daily breakdown of time spent in predefined locations and while traveling
- Includes a date picker to view different days

## Project Structure

The app is organized with a layered architecture:

```
lib/
  ├── animations/        # Custom animations
  ├── components/        # Reusable UI components
  │   ├── clock_button.dart
  │   └── location_summary_card.dart
  ├── models/            # Data models
  │   ├── geofence.dart
  │   ├── location_record.dart
  │   └── location_summary.dart
  ├── providers/         # State management
  │   └── location_provider.dart
  ├── screens/
  │   └── logged_in/     # Main app screens
  │       ├── main_screen.dart
  │       └── summary_screen.dart
  ├── util/              # Utilities and services
  │   ├── database_helper.dart
  │   └── location_service.dart
  └── main.dart          # Entry point
```

## Getting Started

### Prerequisites

- Flutter SDK (2.0.0 or higher)
- Android Studio / Xcode (for mobile development)

### Installation

1. Clone this repository
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app on a connected device or emulator

### Android Configuration

For Android, the app requires several permissions:
- ACCESS_FINE_LOCATION
- ACCESS_COARSE_LOCATION
- ACCESS_BACKGROUND_LOCATION
- FOREGROUND_SERVICE
- WAKE_LOCK

These are already configured in the AndroidManifest.xml file.

## Dependencies

- geolocator: For location tracking
- flutter_background_service: For background location monitoring
- flutter_local_notifications: For displaying notifications when tracking
- shared_preferences: For storing app preferences
- provider: For state management
- sqflite: For local database storage
- path: For file path management
- flutter_map: For displaying maps
- latlong2: For geographic calculations
- intl: For date formatting

## Customization

The sample geofences are defined in the LocationProvider class. Replace these with your own locations by modifying the `_addSampleGeofences()` method.

## License

This project is licensed under the MIT License
