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
