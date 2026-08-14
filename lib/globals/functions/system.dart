import 'package:geolocator/geolocator.dart';

/// Returns true if permissions are allowed
Future<bool> getGeolocatorPermission() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // print('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // print('Location permissions are denied');
    } else {
      return true;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // print('Location permissions are permanently denied.');
  }

  return true;
}
