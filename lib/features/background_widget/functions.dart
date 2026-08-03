import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/api/backend_service.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/computations.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

///
void startComputingForRoutes(BuildContext context) async {
  SystemVariablesProvider systemVariablesProvider = context
      .read<SystemVariablesProvider>();
  MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();

  systemVariablesProvider.setAppCurrentState =
      SystemState.waitingForBackendResponse;

  Map<String, dynamic> backendResponse = await queryForShortestPath(
    mapHelperProvider.getSelectedFromLocationDetails!,
    mapHelperProvider.getSelectedToLocationDetails!,
    context,
    traffic: systemVariablesProvider.includeTraffic,
  );
  if (backendResponse.isEmpty) {
    // queryForShortestPath() will always return a non-empty map if backend response worked.
    throw UnimplementedError(
      "Note to developer: Add a retry button here since the backend response failed.",
    );
  } else {
    mapHelperProvider.setSuggestedShortestPaths = backendResponse;
    systemVariablesProvider.setAppCurrentState =
        SystemState.showSuggestedRoutes;
  }
}

/// Uses the geometry of a route, remake it into a List<LatLng> so the flyToBounds
/// method can be used for proper zooming.
List<LatLng> compileCoordsIntoLatLngList(
  Map<String, dynamic> path,
  String routeId,
) {
  List<LatLng> geometryList = [];
  for (final entry in path["routes"][routeId]) {
    List<LatLng> geometryToAppend = (entry["geometry"] as List<dynamic>).map((
      item,
    ) {
      final coords = (item as List<dynamic>)
          .map((coord) => (coord as num).toDouble())
          .toList();
      return LatLng(coords[1], coords[0]); // [lng, lat] → LatLng(lat, lng)
    }).toList();

    geometryList.addAll(geometryToAppend);
  }
  return geometryList;
}

/// Uses Haversine Formula to get proper distance based on Lat Lon values.
///
/// Returns time in seconds
double computeTravel(Map<String, dynamic> routeData, String route_id) {
  double travelTimeInSeconds = 0;
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
      return LatLng(coords[1], coords[0]); // [lng, lat] → LatLng(lat, lng)
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

    String modeType = entry["mode"]["type"].toString();
    if (modeType == "walk") {
      double travelDuration = (distanceInKM / (4.5 / 3600));
      travelTimeInSeconds += travelDuration;
    } else if (modeType == "jeep") {
      double travelDuration = (distanceInKM / (14 / 3600));
      travelTimeInSeconds += travelDuration;
    } else if (modeType == "trike") {
      double travelDuration = (distanceInKM / (23 / 3600));
      travelTimeInSeconds += travelDuration;
    }
  }

  return travelTimeInSeconds;
}

/// Returns the total walking distance in kilometers of a route by summing
/// the haversine distances of all its walk segments.
double computeTotalWalkingDistance(
  Map<String, dynamic> routeData,
  String routeId,
) {
  double walkingDistanceInKM = 0;
  for (final entry in routeData["routes"][routeId]) {
    if (entry["mode"]["type"] != "walk") continue;

    List<LatLng> geometryDetails = (entry["geometry"] as List<dynamic>).map((
      item,
    ) {
      final coords = (item as List<dynamic>)
          .map((coord) => (coord as num).toDouble())
          .toList();
      return LatLng(coords[1], coords[0]); // [lng, lat] → LatLng(lat, lng)
    }).toList();

    for (int i = 0; i < geometryDetails.length - 1; i++) {
      walkingDistanceInKM += getDistanceFromLatLonInKm(
        geometryDetails[i].latitude,
        geometryDetails[i].longitude,
        geometryDetails[i + 1].latitude,
        geometryDetails[i + 1].longitude,
      );
    }
  }
  return walkingDistanceInKM;
}

/// Counts the number of jeepney and tricycle rides (transfers) in a route.
int countTransfersForRoute(Map<String, dynamic> routeData, String routeId) {
  int transferCount = 0;
  for (final entry in routeData["routes"][routeId]) {
    String modeType = entry["mode"]["type"].toString();
    if (modeType == "jeep" || modeType == "trike") {
      transferCount++;
    }
  }
  return transferCount;
}

/// Computes which badges a route deserves by comparing it against all other
/// returned routes. Badges are only given when at least two routes exist.
///
/// The "Least Transfers" badge is withheld entirely when multiple routes tie
/// for the fewest transfers.
Set<String> computeRouteBadges(
  Map<String, dynamic> routeData,
  String routeId,
) {
  Set<String> badges = {};
  Map<String, dynamic> routes = routeData["routes"];
  if (routes.length < 2) return badges;

  double fastestTime = double.infinity;
  double leastWalk = double.infinity;
  int fewestTransfers = 1 << 30;
  int transferWinners = 0;
  int leastWalkWinners = 0;
  String? fastestRouteId;

  for (final id in routes.keys) {
    double time = computeTravel(routeData, id);
    double walk = computeTotalWalkingDistance(routeData, id);
    int transfers = countTransfersForRoute(routeData, id);

    if (time < fastestTime) {
      fastestTime = time;
      fastestRouteId = id;
    }
    if (walk < leastWalk) {
      leastWalk = walk;
      leastWalkWinners = 1;
    } else if (walk == leastWalk) {
      leastWalkWinners++;
    }
    if (transfers < fewestTransfers) {
      fewestTransfers = transfers;
      transferWinners = 1;
    } else if (transfers == fewestTransfers) {
      transferWinners++;
    }
  }

  if (fastestRouteId == routeId) {
    badges.add("Fastest Route");
  }
  if (leastWalkWinners == 1 &&
      computeTotalWalkingDistance(routeData, routeId) == leastWalk) {
    badges.add("Least Walking");
  }
  if (transferWinners == 1 &&
      countTransfersForRoute(routeData, routeId) == fewestTransfers) {
    badges.add("Least Transfers");
  }
  return badges;
}

/// Creates a CustomPaint widget that visualizes travel details in color
CustomPaint navPainter(Map<String, dynamic> routeData, String routeId) {
  // Store entry details for later use. Must be formatted like this:
  // [Entry Count, Mode Type, Mode Color (may be null)]
  List<List<dynamic>> entryDetailsForPainting = [];

  // This needs to be known to properly divide each entry in the CustomPainter
  int totalVertexCount = 0;

  // ///////////////////////////////////////////////////////////////////////

  // Extract data from route details
  for (final entry in routeData["routes"][routeId]) {
    // Each entry here represents a chop piece in the route caused by switching between
    // transpo modes like: walk -> jeep -> walk

    String routeModeType = entry["mode"]["type"];
    String hexColor = entry["mode"]["details"]["color"];

    List<LatLng> geometryDetails = (entry["geometry"] as List<dynamic>).map((
      item,
    ) {
      final coords = (item as List<dynamic>)
          .map((coord) => (coord as num).toDouble())
          .toList();
      return LatLng(coords[1], coords[0]); // [lng, lat] → LatLng(lat, lng)
    }).toList();
    totalVertexCount += geometryDetails.length;
    entryDetailsForPainting.add([
      geometryDetails
          .length, // to identify the % makeup of that entry in the entire route
      routeModeType, // to identify whether to do a chopped or a straight line
      hexColor, // for the paint's color
    ]);
  }

  // ///////////////////////////////////////////////////////////////////////

  return CustomPaint(
    size: Size(double.infinity, 4), // width x height of the line
    painter: _LinePainter(entryDetailsForPainting, totalVertexCount),
  );
}

class _LinePainter extends CustomPainter {
  List<List<dynamic>> entryDetailsForPainting = [];
  int totalVertexCount = 0;

  _LinePainter(this.entryDetailsForPainting, this.totalVertexCount);

  @override
  void paint(Canvas canvas, Size size) {
    /// Will progressively go up to properly position the next entries
    /// and to avoid unwanted overlaps
    double currentPlaceToDraw = 0;

    for (final entry in entryDetailsForPainting) {
      double percentMakeup = (entry[0] as int) / totalVertexCount;
      String routeType = entry[1];
      String hexColor = entry[2];
      Color color = Color(int.parse(hexColor.replaceAll('#', 'FF'), radix: 16));

      if (routeType == "jeep" || routeType == "trike") {
        canvas.drawLine(
          Offset(currentPlaceToDraw, size.height / 2),
          Offset(
            currentPlaceToDraw + (size.width * percentMakeup),
            size.height / 2,
          ),
          Paint()
            ..color = color
            ..strokeWidth = 4,
        );

        // Make the points that indicate marker for jeepney travel
        canvas.drawCircle(
          Offset(currentPlaceToDraw, size.height / 2),
          6,
          Paint()..color = color,
        );
        canvas.drawCircle(
          Offset(currentPlaceToDraw, size.height / 2),
          3,
          Paint()..color = Colors.white,
        );

        currentPlaceToDraw +=
            size.width *
            percentMakeup; // To push the next entries at the right side of this
      } else if (routeType == "walk") {
        double startX = currentPlaceToDraw;
        double endX = currentPlaceToDraw + size.width * percentMakeup;
        final double tickSpacing = 8; // gap between each tick
        final double tickHeight = 6; // how tall each vertical tick is

        double x = startX;

        while (x < endX) {
          canvas.drawLine(
            Offset(x, size.height / 2 - tickHeight / 2),
            Offset(x, size.height / 2 + tickHeight / 2),
            Paint()
              ..color = color
              ..strokeWidth = 2
              ..style = PaintingStyle.stroke,
          );
          x += tickSpacing;
        }

        currentPlaceToDraw += size.width * percentMakeup;
      }
    }

    // Dots at the ends
    canvas.drawCircle(
      Offset(0, size.height / 2),
      6,
      Paint()..color = Color.fromARGB(255, 0, 94, 255),
    );
    canvas.drawCircle(
      Offset(0, size.height / 2),
      3,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      Offset(size.width, size.height / 2),
      6,
      Paint()..color = Color.fromARGB(255, 0, 94, 255),
    );
    canvas.drawCircle(
      Offset(size.width, size.height / 2),
      3,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Computes the total expected and actual duration for a route by summing
/// the traffic data from each segment.
///
/// Returns (expectedDuration, actualDuration) in seconds.
/// Falls back to computeTravel() if traffic data is missing.
(int, int) computeRouteDelay(
  Map<String, dynamic> routeData,
  String routeId,
) {
  int totalExpected = 0;
  int totalActual = 0;
  bool hasTrafficData = false;

  for (final entry in routeData["routes"][routeId]) {
    if (entry.containsKey("traffic") &&
        entry["traffic"] != null &&
        entry["traffic"].containsKey("expectedDuration") &&
        entry["traffic"].containsKey("actualDuration")) {
      hasTrafficData = true;
      totalExpected += (entry["traffic"]["expectedDuration"] as num).toInt();
      totalActual += (entry["traffic"]["actualDuration"] as num).toInt();
    }
  }

  if (!hasTrafficData) {
    // Fallback: use Haversine-based computation for both
    int haversineTime = computeTravel(routeData, routeId).toInt();
    return (haversineTime, haversineTime);
  }

  return (totalExpected, totalActual);
}

/// To check if a nominatim result points to a place that's within the thesis's
/// scope, which is Angeles City and Mabalacat/Dau of Central Luzon
bool isPlaceWithinScope(String fullAddress) {
  // possible entries of angeles city and mabalacat/dau
  List<String> validAddresses = ["angeles", "mabalacat", "dau"];
  // there might be a chance where angeles/mabalacat/dau names can be
  // present outside of central luzon
  List<String> requiredAddresses = ["central luzon"];

  bool hasValidAddress = false;
  bool hasRequiredAddress = false;

  // displayName result of NominatimPlace has its details separated with ", "
  List<String> segmentedAddress = fullAddress.split(", ");
  for (String segmentAddress in segmentedAddress) {
    if (validAddresses.contains(segmentAddress.toLowerCase())) {
      hasValidAddress = true;
    }
    if (requiredAddresses.contains(segmentAddress.toLowerCase())) {
      hasRequiredAddress = true;
    }
  }
  return hasValidAddress && hasRequiredAddress;
}
