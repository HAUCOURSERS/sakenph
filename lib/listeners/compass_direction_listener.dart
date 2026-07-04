import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:flutter_device_compass/flutter_device_compass.dart';

Future<void> requestPermissionAndListenForCompassDirection(
  BuildContext context,
) async {
  MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();

  // Required on Android
  if (await Permission.locationWhenInUse.request().isGranted) {
    FlutterCompass.events!.listen((CompassEvent event) {
      //print("[TEMP] COMPASS VALUE: ${event.heading}");
      double heading = (event.heading! + 360) % 360;
      //print("[TEMP] COMPASS VALUE: ${heading}");

      mapHelperProvider.setUserCompassRotation = heading;
    });
  }
}
