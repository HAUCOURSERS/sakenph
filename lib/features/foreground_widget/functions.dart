import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/formattings.dart';
import 'package:sakenph/globals/functions/route_timing.dart';
import 'package:sakenph/globals/variables.dart' as global_vars show localIP;
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_system_tasks.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

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
/// it will return a List of data tuples.
///
/// Data format:
/// - Walk/Jeep Name
/// - Color
/// - Distance in meters
/// - Fare Rate (Formatted or Blank if no fare)
/// - Estimated travel time in seconds (from traffic data or Haversine fallback)
/// - Delay in seconds (actualDuration - expectedDuration, 0 if no traffic data)
List<(String, String, double, String, int, int, int, String)>
buildTravelDetails(Map<String, dynamic> routeData, String route_id) {
  List<(String, String, double, String, int, int, int, String)> returnDetails =
      [];
  final entries = routeData["routes"][route_id] as List<dynamic>;
  final timings = computeRouteTiming(routeData, route_id).segments;
  for (int segmentIndex = 0; segmentIndex < entries.length; segmentIndex++) {
    final entry = entries[segmentIndex] as Map<String, dynamic>;
    final timing = timings[segmentIndex];
    final distanceInKM = timing.distanceInKm;
    String routeColor = entry["mode"]["details"]["color"].toString();
    double fareRegular = entry["mode"]["details"]["fare"]["regular"];
    double fareDiscounted = entry["mode"]["details"]["fare"]["discounted"];
    String modeType = entry["mode"]["type"].toString();
    final isZeroDistanceTransfer =
        modeType == "walk" &&
        distanceInKM < 0.001 &&
        timing.actualSeconds == 0 &&
        timing.delaySeconds == 0;

    int segmentTravelTime = timing.actualSeconds;
    int segmentDelay = timing.delaySeconds;
    int transferWait = timing.transferWaitSeconds;

    if (modeType == "walk") {
      returnDetails.add((
        isZeroDistanceTransfer ? zeroDistanceTransferLabel : "Walk",
        routeColor,
        (distanceInKM * 1000),
        "",
        segmentTravelTime,
        segmentDelay,
        transferWait,
        modeType,
      ));
    } else if (modeType == "jeep") {
      String jeepName = entry["mode"]["details"]["name"].toString();
      returnDetails.add((
        formatLabelForJeepneyName(jeepName),
        routeColor,
        (distanceInKM * 1000),
        "${fareRegular.toStringAsFixed(2)}₱ / ${fareDiscounted.toStringAsFixed(2)}₱",
        segmentTravelTime,
        segmentDelay,
        transferWait,
        modeType,
      ));
    } else if (modeType == "trike") {
      String todaTerminal = entry["mode"]["details"]["name"].toString();
      returnDetails.add((
        "Tricycle - $todaTerminal",
        routeColor,
        (distanceInKM * 1000),
        "${fareRegular.toStringAsFixed(2)}₱ / ${fareDiscounted.toStringAsFixed(2)}₱",
        segmentTravelTime,
        segmentDelay,
        transferWait,
        modeType,
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
