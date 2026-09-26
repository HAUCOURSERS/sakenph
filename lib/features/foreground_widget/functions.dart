import 'dart:convert';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/api/nominatim.dart';
import 'package:sakenph/classes/nominatim_response.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/fore_and_background_functions.dart';
import 'package:sakenph/globals/functions/formattings.dart';
import 'package:sakenph/globals/functions/route_timing.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';
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

/// Used by the textfields to decide the color of the textfield.<br/>
/// @param isFocused - if true, the color would forcefully be white. Otherwise, it will be red/green depending on hasSelectedValidLocation<br/>
/// @param hasSelectedValidLocation - the boolean value is usually supplied by the function user. Check MapHelperProvider if there's saved information regarding to from/to location details
Color manageTextfieldColor(
  bool isFocused,
  bool hasSelectedValidLocation,
  bool isTextfieldEmpty,
) {
  if (isFocused && isTextfieldEmpty) return Colors.white;
  if (hasSelectedValidLocation) return Color.fromARGB(255, 188, 230, 199);
  if (!isFocused && !hasSelectedValidLocation && !isTextfieldEmpty)
    return Color.fromARGB(255, 230, 188, 188);
  return Colors.white;
}

/// Used by FromLocationSearchBar.
void fromLocTextFieldOnChanged(
  SearchDetailsProvider searchDetailsProvider,
  String value,
  MapHelperProvider mapHelperProvider,
) {
  /// Auto-wipe the selected loc details per textfield modification to deal with use case where the user forgets to change their choice and unexpected results would occur.
  mapHelperProvider.tryToEraseSelectedFromLocDetails();

  /// Auto-wipes the textfield if any modification is done while the textfield is special.
  if (searchDetailsProvider.isInputSpecial_fromLoc) {
    // To return it back to normal
    searchDetailsProvider.setFromLocTextfieldHintText = "Your Location";
    // To disable the fast delete behavior of FromLocTextField
    searchDetailsProvider.setIsInputSpecial_fromLoc = false;
    // To hide the dropdown results
    searchDetailsProvider.setActiveSearching_fromLoc = false;
  } else {
    // Keeps the location results clean while typing
    searchDetailsProvider.tryToEraseLocResults(SearchFieldType.from);
    // Hides the retry button since the user attempts to search once more
    searchDetailsProvider.setIsNominatimSearchFailed_TypeFrom = false;
    // Makes the dropdown results able to appear
    searchDetailsProvider.setActiveSearching_fromLoc = value.isNotEmpty;
    if (value.isNotEmpty) {
      EasyDebounce.debounce(
        DebounceId.nominatim_fromLocationSearch.toString(),
        Duration(seconds: 2),
        () async {
          searchDetailsProvider.saveLocSearchResults(
            await searchPlaces(
              value,
              searchDetailsProvider,
              SearchFieldType.from,
            ),
            SearchFieldType.from,
          );
        },
      );
    } else {
      /// Covers the use case of: If the user clears out the entire textfield section
      EasyDebounce.cancel(DebounceId.nominatim_fromLocationSearch.toString());
    }
  }
}

/// Used by ToLocationSearchBar.
void toLocTextFieldOnChanged(
  SearchDetailsProvider searchDetailsProvider,
  String value,
  MapHelperProvider mapHelperProvider,
) {
  /// Auto-wipe the selected loc details per textfield modification to deal with use case where the user forgets to change their choice and unexpected results would occur.
  mapHelperProvider.tryToEraseSelectedToLocDetails();

  /// Auto-wipes the textfield if any modification is done while the textfield is special.
  if (searchDetailsProvider.isInputSpecial_toLoc) {
    // To return it back to normal
    searchDetailsProvider.setToLocTextfieldHintText = "Your Destination";
    // To disable the fast delete behavior of FromLocTextField
    searchDetailsProvider.setIsInputSpecial_toLoc = false;
    // To hide the dropdown results
    searchDetailsProvider.setActiveSearching_toLoc = false;
  } else {
    // Keeps the location results clean while typing
    searchDetailsProvider.tryToEraseLocResults(SearchFieldType.to);
    // Hides the retry button since the user attempts to search once more
    searchDetailsProvider.setIsNominatimSearchFailed_TypeTo = false;
    // Makes the dropdown results able to appear
    searchDetailsProvider.setActiveSearching_toLoc = value.isNotEmpty;
    if (value.isNotEmpty) {
      EasyDebounce.debounce(
        DebounceId.nominatim_toLocationSearch.toString(),
        Duration(seconds: 2),
        () async {
          searchDetailsProvider.saveLocSearchResults(
            await searchPlaces(
              value,
              searchDetailsProvider,
              SearchFieldType.to,
            ),
            SearchFieldType.to,
          );
        },
      );
    } else {
      /// Covers the use case of: If the user clears out the entire textfield section
      EasyDebounce.cancel(DebounceId.nominatim_fromLocationSearch.toString());
    }
  }
}

/// Tries to get the first valid result of a textfield's search field and save it
/// for later use.
void tryToGetFirstResultAndSave(
  SearchDetailsProvider searchDetailsProvider,
  SearchFieldType searchFieldType,
  MapHelperProvider mapHelperProvider,
  SystemVariablesProvider systemVariablesProvider,
  BuildContext context,
) {
  NominatimPlace? firstResult = searchDetailsProvider
      .getFirstValidPlaceSearchResult(searchFieldType);

  // The null check is important to prevent unwanted api calls due to incorrect information
  if (firstResult == null) return;
  processLocationInformation(
    searchFieldType,
    mapHelperProvider,
    searchDetailsProvider,
    systemVariablesProvider,
    context,
    firstResult,
    false,
  );
}
