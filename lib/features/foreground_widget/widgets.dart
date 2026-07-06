import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sakenph/api/nominatim.dart';
import 'package:sakenph/features/foreground_widget/functions.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_tasks.dart';
import 'package:sakenph/providers/provider_system_vars.dart';
import 'package:sakenph/pages/settings_page.dart' show SettingsPage;
import 'package:provider/provider.dart';
import 'dart:math' as Math;

import '../../providers/provider_map_helper.dart';

/// The main widget for the Foreground. Any widgets that are needed to be displayed
/// at the top of the main widget's stack is written here.
class ForegroundWidget extends StatefulWidget {
  const ForegroundWidget({super.key});

  @override
  State<ForegroundWidget> createState() => _ForegroundWidgetState();
}

class _ForegroundWidgetState extends State<ForegroundWidget> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(children: [_ForegroundWidgetContentRenderer()]),
    );
  }
}

/// Relies on the value of [SystemVariablesProvider.appCurrentState] to
/// decide what to render.
class _ForegroundWidgetContentRenderer extends StatelessWidget {
  const _ForegroundWidgetContentRenderer();

  @override
  Widget build(BuildContext context) {
    bool isFromLocDetailsEmpty = context.select<MapHelperProvider, bool>(
      (value) => !value.getIsFromLocationDetailsEmpty,
    );
    bool hasSearchedForRoutes = context.select<MapHelperProvider, bool>(
      (value) => !value.getIsSuggestedShortestPathsEmpty,
    );
    SystemState systemState = context
        .select<SystemVariablesProvider, SystemState>(
          (value) => value.appCurrentState,
        );
    bool backgroundWidgetVisibility = context
        .select<SystemVariablesProvider, bool>(
          (value) => value.backgroundWidgetVisibility,
        );
    switch (systemState) {
      case SystemState.gatheringFromLoc:
      case SystemState.gatheringToLoc:
      case SystemState.waitingForBackendResponse:
      case SystemState.showSuggestedRoutes:
      case SystemState.backendRequestFail:
        return (isFromLocDetailsEmpty)
            ? _FromLocationSearchBar()
            : Column(
                children: [
                  _FromLocationSearchBar(),
                  _ToLocationSearchBar(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: (hasSearchedForRoutes && !backgroundWidgetVisibility)
                        ? _RouteOpenerButton()
                        : SizedBox.shrink(),
                  ),
                ],
              );
      case SystemState.peekAtRoute:
        return _PreviewWindowForSuggestedPath();
      case SystemState.hideWidgets:
        return SizedBox.shrink();
      case SystemState.isCurrentlyTravelling:
        return _ActiveRouteTerminator();
    }
  }
}

/// A textfield widget that is used by the user to input their origin location
class _FromLocationSearchBar extends StatelessWidget {
  const _FromLocationSearchBar();

  @override
  Widget build(BuildContext context) {
    SearchDetailsProvider searchDetailsProvider = context
        .read<SearchDetailsProvider>();

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.95,
        child: Column(
          children: [
            TextField(
              controller: searchDetailsProvider.getFromLocTextController,
              onChanged: (value) {
                searchDetailsProvider.tryToEraseLocResults(
                  SearchFieldType.from,
                );
                searchDetailsProvider.setIsNominatimSearchFailed_TypeFrom =
                    false;
                searchDetailsProvider.setActiveSearching_fromLoc =
                    value.isNotEmpty;
                if (value.isNotEmpty) {
                  EasyDebounce.debounce(
                    DebounceId.nominatim_fromLocationSearch.toString(),
                    Duration(seconds: 1),
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
                  EasyDebounce.cancel(
                    DebounceId.nominatim_fromLocationSearch.toString(),
                  );
                }
              },
              style: TextStyle(fontSize: 18),
              onTap: () {
                context
                        .read<SystemVariablesProvider>()
                        .setBackgroundWidgetVisibility =
                    true;
                context.read<SystemVariablesProvider>().setAppCurrentState =
                    SystemState.gatheringFromLoc;
              },
              decoration: InputDecoration(
                /// Expected to change state whether the background widget is
                /// visible or not
                prefixIcon:
                    context.select<SystemVariablesProvider, bool>(
                      (varval) => (varval.backgroundWidgetVisibility),
                    )
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            context
                                    .read<SystemVariablesProvider>()
                                    .setBackgroundWidgetVisibility =
                                false;
                          },
                          child: Icon(Icons.arrow_back),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            context
                                    .read<SystemVariablesProvider>()
                                    .setBackgroundWidgetVisibility =
                                true;
                          },
                          child: Icon(Icons.search),
                        ),
                      ),
                hintText: "Your Location",
                suffixIcon: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
                  },
                  child: Icon(Icons.settings),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _ToLocationSearchBar extends StatelessWidget {
  const _ToLocationSearchBar();

  @override
  Widget build(BuildContext context) {
    SearchDetailsProvider searchDetailsProvider = context
        .read<SearchDetailsProvider>();
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.95,
        child: Column(
          children: [
            TextField(
              focusNode: searchDetailsProvider.getToLocFocusNode,
              controller: searchDetailsProvider.getToLocTextController,
              onChanged: (value) {
                searchDetailsProvider.tryToEraseLocResults(SearchFieldType.to);
                searchDetailsProvider.setIsNominatimSearchFailed_TypeTo = false;
                searchDetailsProvider.setActiveSearching_toLoc =
                    value.isNotEmpty;
                if (value.isNotEmpty) {
                  EasyDebounce.debounce(
                    DebounceId.nominatim_toLocationSearch.toString(),
                    Duration(seconds: 1),
                    () async {
                      context
                          .read<SearchDetailsProvider>()
                          .saveLocSearchResults(
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
                  EasyDebounce.cancel(
                    DebounceId.nominatim_fromLocationSearch.toString(),
                  );
                }
              },
              style: TextStyle(fontSize: 18),
              onTap: () {
                context
                        .read<SystemVariablesProvider>()
                        .setBackgroundWidgetVisibility =
                    true;
                context.read<SystemVariablesProvider>().setAppCurrentState =
                    SystemState.gatheringToLoc;
              },
              decoration: InputDecoration(
                /// Expected to change state whether the background widget is
                /// visible or not
                hintText: "Your Destination",
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 48,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// Holds 2 buttons for the user to try see the path in the map.
/// It's intentional by design that the map cannot be interacted while in this mode
class _PreviewWindowForSuggestedPath extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.sizeOf(context).height * 0.75,
          left: MediaQuery.sizeOf(context).width * 0.125,
          right: MediaQuery.sizeOf(context).width * 0.125,
          child: GestureDetector(
            child: Container(
              height: 200,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      context
                              .read<SystemVariablesProvider>()
                              .setAppCurrentState =
                          SystemState.showSuggestedRoutes;
                      context
                          .read<MapHelperProvider>()
                          .mapWidgetController
                          .clearLayersAndSources();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          30,
                        ), // rounded, not circle
                        color: Colors.grey.shade300, // perfect circle
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4), // x, y offset
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Go Back",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      startTraveling(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          30,
                        ), // rounded, not circle
                        color: Colors.grey.shade300, // perfect circle
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4), // x, y offset
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Select This Route",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Appears if the user has queried for routes and valid routes showed up. Relying
/// on the search button is useless since it's hard to press on screen
class _RouteOpenerButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () {
          context.read<SystemVariablesProvider>().setAppCurrentState =
              SystemState.showSuggestedRoutes;
          context
                  .read<SystemVariablesProvider>()
                  .setBackgroundWidgetVisibility =
              true;
        },
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.75,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 176, 221, 255),
            border: Border.all(width: 1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "View Searched Routes",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// If the user wants to terminate their travel towards a location, select this.
class _ActiveRouteTerminator extends StatelessWidget {
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
        SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            context.read<SystemVariablesProvider>().setAppCurrentState =
                SystemState.showSuggestedRoutes;
            context
                .read<MapHelperProvider>()
                .mapWidgetController
                .clearLayersAndSources();
            context.read<SystemTasksProvder>().stop_repeatingTask();
          },
          child: Center(
            child: Column(
              children: [
                Container(
                  width: MediaQuery.sizeOf(context).width * 0.95,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: distanceTillDestinationInMeters < 20
                        ? Colors.green
                        : Colors.red,
                    border: Border.all(width: 1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    "Stop Tracking",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(
                    left: 30,
                    right: 30,
                    top: 5,
                    bottom: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    border: Border.all(width: 1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    "Distance till Destination: ${distanceTillDestinationInMeters.toStringAsFixed(2)} m",
                    style: TextStyle(color: Colors.black, fontSize: 20),
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
