import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/computations.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_system_tasks.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// If the user wants to terminate their travel towards a location, select this.
class ActiveRouteTerminator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // force the widget to re-render every time the user moves, so that the distance till destination is updated
    context.select<MapHelperProvider, LatLng>(
      (value) => value.getUserCurrentGeoLoc,
    );
    double distanceTillDestinationInMeters =
        getDistanceFromLatLonInKm(
          context.read<MapHelperProvider>().getUserCurrentGeoLoc.latitude,
          context.read<MapHelperProvider>().getUserCurrentGeoLoc.longitude,
          context
              .read<MapHelperProvider>()
              .getSelectedToLocationDetails!
              .latitude,
          context
              .read<MapHelperProvider>()
              .getSelectedToLocationDetails!
              .longitude,
        ) *
        1000;
    return Column(
      children: [
        SizedBox(height: responsiveSizeHeight(20)),
        GestureDetector(
          onTap: () async {
            MapHelperProvider mapHelperProvider = context
                .read<MapHelperProvider>();
            context.read<SystemVariablesProvider>().setAppCurrentState =
                SystemState.showSuggestedRoutes;
            context.read<SystemTasksProvder>().stop_repeatingTask();

            // First, stop potential edge drawings and after 40 milliseconds,
            // there should be no follow-up drawings, making node deletion secure.
            mapHelperProvider.setStopDrawing = true;
            await Future.delayed(Duration(milliseconds: 40));
            mapHelperProvider.mapWidgetController.clearLayersAndSources();
            mapHelperProvider.setStopDrawing = false;
          },
          child: Center(
            child: Column(
              children: [
                Container(
                  width: responsiveSizeWidth(
                    MediaQuery.sizeOf(context).width * 0.95,
                    500,
                  ),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: distanceTillDestinationInMeters < 20
                        ? Colors.green
                        : Colors.red,
                    border: Border.all(width: responsiveSizeHeight(1)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    "Stop Tracking",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: max(20, responsiveSizeHeight(20)),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(
                    left: responsiveSizeWidth(30),
                    right: responsiveSizeWidth(30),
                    top: responsiveSizeHeight(5),
                    bottom: responsiveSizeHeight(5),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    border: Border.all(width: responsiveSizeHeight(1)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    "Distance till Destination: ${distanceTillDestinationInMeters.toStringAsFixed(2)} m",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: max(18, responsiveSizeHeight(20)),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
