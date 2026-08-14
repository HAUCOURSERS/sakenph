import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_map_helper.dart';

/// To get location perms
Future<bool> handleLocationPermission(BuildContext context) async {
  if (!context.mounted) return false;
  bool serviceEnabled;
  LocationPermission permission;
  MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();

  ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Location services are disabled. Please enable the services',
        ),
      ),
    );
    return false;
  }
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Location permissions are denied')),
      );
      return false;
    }
  }
  if (permission == LocationPermission.deniedForever) {
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Location permissions are permanently denied, we cannot request permissions.',
        ),
      ),
    );
    return false;
  }
  mapHelperProvider.fetchUserCurrentGeolocationAndSave();
  return true;
}
