import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_map_helper.dart';

Future<void> requestPermissionAndListen(BuildContext context) async {
  MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();

  // Required on Android
  if (await Permission.locationWhenInUse.request().isGranted) {
    FlutterCompass.events!.listen((CompassEvent event) {
      //print("[TEMP] COMPASS VALUE: ${event.heading}");
      double heading = (event.heading! + 180) % 360;
      //print("[TEMP] COMPASS VALUE: ${heading}");

      mapHelperProvider.setUserCompassRotation = heading;
    });
  }
}
