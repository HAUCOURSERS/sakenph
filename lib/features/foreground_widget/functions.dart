import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/formattings.dart';
import 'package:sakenph/globals/functions/route_timing.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_system_tasks.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

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
