import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';

import '../providers/provider_system_vars.dart';

/// Function that contains all code to run in interval
void runRepeatingTaskJobs(BuildContext context) async {
  //print("REPEAT JOB: GET AND STORE CURRENT LOC DETAILS");
  context.read<SearchDetailsProvider>().getUserCurrentLocAndSaveToContext(
    context,
  );

  // If the user is currently tracking, start spawning the marker
  if (context.read<SystemVariablesProvider>().appCurrentState ==
      SystemState.isCurrentlyTravelling) {
    print("[TEMP] Executing reloading of user marker");
    LatLng coords = context.read<SearchDetailsProvider>().getUserCurrentGeoLoc;
    context.read<MapHelperProvider>().shiftPosition(coords);
    double rotation = context
        .read<MapHelperProvider>()
        .getMovementDirectionFromYourPositionHistory();

    await context
        .read<SearchDetailsProvider>()
        .mapWidgetController
        .addUserMarker(coords, rotation);
  }
}
