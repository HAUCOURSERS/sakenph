import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions.dart';

import 'package:sakenph/globals/variables.dart' as global_vars show localIP;
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_system_tasks.dart';
import 'package:sakenph/providers/provider_system_vars.dart';
import 'dart:math';

/// Currently has no uses
Future<String> reverseGeocode({
  required double longitude,
  required double latitude,
}) async {
  final response = await http.get(
    Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=jsonv2',
    ),
  );

  if (response.statusCode == 200) {
    Map<String, dynamic> jsonObject = jsonDecode(response.body);

    return jsonObject['display_name'];
  } else {
    throw Exception('Failed to load JSON');
  }
}

/// Currently used to test connection towards backend.
/// If connection is successful, it will return "Hello from FastAPI!"
Future<Map<String, dynamic>> fetchData() async {
  String localIp = global_vars.localIP;
  final response = await http.get(
    Uri.parse('http://${localIp}:8000/flutterTest'),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load JSON');
  }
}

/// To get location perms
Future<bool> handleLocationPermission(BuildContext context) async {
  if (!context.mounted) return false;
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are denied')),
      );
      return false;
    }
  }
  if (permission == LocationPermission.deniedForever) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Location permissions are permanently denied, we cannot request permissions.',
        ),
      ),
    );
    return false;
  }
  return true;
}

/// Runs the necessary code across context providers to setup the traveling state
void startTraveling(BuildContext context) async {
  // Hide every other option to focus on travelling
  context.read<SystemVariablesProvider>().setBackgroundWidgetVisibility = false;
  context.read<SystemVariablesProvider>().setAppCurrentState =
      SystemState.isCurrentlyTravelling;

  // Immediately set the marker
  LatLng coords = context.read<MapHelperProvider>().getUserCurrentGeoLoc;
  context.read<MapHelperProvider>().mapWidgetController.flyToLoc(coords);

  context.read<SystemTasksProvder>().start_repeatingTask();

  await context.read<MapHelperProvider>().mapWidgetController.addUserMarker(
    coords,
    0,
  );
}

/// Upon providing the JSON return of backend along with the route_id of your choice,
/// it will return a List<(String, double)> of data.
///
/// Data format:
/// - Walk/Jeep Name
/// - Color
/// - Distance in meters
List<(String, String, double)> buildTravelDetails(
  Map<String, dynamic> routeData,
  String route_id,
) {
  List<(String, String, double)> returnDetails = [];
  for (final entry in routeData["routes"][route_id]) {
    double distanceInKM = 0;
    // Each entry here represents a chop piece in the route caused by switching between
    // transpo modes like: walk -> jeep -> walk
    List<LatLng> geometryDetails = (entry["geometry"] as List<dynamic>).map((
      item,
    ) {
      final coords = (item as List<dynamic>)
          .map((coord) => (coord as num).toDouble())
          .toList();
      return LatLng(coords[1], coords[0]);
    }).toList();

    // At this point, start computing the distance between in km
    for (int i = 0; i < geometryDetails.length - 1; i++) {
      distanceInKM += getDistanceFromLatLonInKm(
        geometryDetails[i].latitude,
        geometryDetails[i].longitude,
        geometryDetails[i + 1].latitude,
        geometryDetails[i + 1].longitude,
      );
    }
    String routeColor = entry["mode"]["details"]["color"].toString();
    String modeType = entry["mode"]["type"].toString();
    if (modeType == "walk") {
      returnDetails.add(("Walk", routeColor, (distanceInKM * 1000)));
    } else if (modeType == "jeep") {
      String jeepName = entry["mode"]["details"]["name"].toString();
      returnDetails.add((
        formatLabelForJeepneyName(jeepName),
        routeColor,
        (distanceInKM * 1000),
      ));
    }
  }

  return returnDetails;
}

/// Returns a grouped double values that totals the fare amount
(double, double) computeFareTotalForRoute(
  Map<String, dynamic> routeData,
  String route_id,
) {
  double totalAmt = 0;
  double totalAmtDiscounted = 0;

  for (final entry in routeData["routes"][route_id]) {
    Map<String, dynamic> fareDetails = entry["mode"]["details"];
    totalAmt += fareDetails["fare"] == null
        ? 0
        : double.parse(fareDetails["fare"]["regular"].toString());
    totalAmtDiscounted += fareDetails["fare"] == null
        ? 0
        : double.parse(fareDetails["fare"]["discounted"].toString());
  }

  return (totalAmt, totalAmtDiscounted);
}
