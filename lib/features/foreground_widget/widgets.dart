import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sakenph/api/nominatim.dart';
import 'package:sakenph/features/background_widget/functions.dart';
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
    MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();
    bool isFromLocDetailsEmpty = context.select<MapHelperProvider, bool>(
      (value) => value.getIsFromLocationDetailsEmpty,
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
        return _PreviewWindowForSuggestedPath(
          routeDetails: mapHelperProvider.getSuggestedShortestPaths,
        );
      case SystemState.hideWidgets:
        return SizedBox.shrink();
      case SystemState.isCurrentlyTravelling:
        return _ActiveRouteTerminator();
      case SystemState.confirmingLocationSelection:
        return _SelectedLocationDecisionHelper();
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

/// When the user selects a path from the suggested paths display, the widgets
/// that will show up will come from this.
///
/// Includes the go back, select route, walk details and total fare from transportation
/// methods.
class _PreviewWindowForSuggestedPath extends StatelessWidget {
  final Map<String, dynamic> routeDetails;

  const _PreviewWindowForSuggestedPath({super.key, required this.routeDetails});

  @override
  Widget build(BuildContext context) {
    SystemVariablesProvider systemVariablesProvider = context
        .read<SystemVariablesProvider>();
    return PopScope(
      canPop:
          systemVariablesProvider.appCurrentState != SystemState.peekAtRoute,
      onPopInvokedWithResult: (didPop, result) async {
        await Future.delayed(Duration(milliseconds: 20));
        systemVariablesProvider.setAppCurrentState =
            SystemState.showSuggestedRoutes;
      },
      child: Stack(
        children: [
          Positioned(
            bottom: MediaQuery.sizeOf(context).height * 0.03125,
            left: MediaQuery.sizeOf(context).width * 0.125,
            right: MediaQuery.sizeOf(context).width * 0.125,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.all(Radius.circular(5)),
              ),
              child: Column(
                children: [
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5),
                      ),
                    ),
                  ),

                  Container(color: Colors.black, height: 2),
                  _RouteDetailsBuilder(),
                  Container(
                    width: double.infinity,
                    color: Colors.black,
                    height: 2,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            EasyDebounce.debounce(
                              DebounceId.routeSelection.toString(),
                              Duration(milliseconds: 40),
                              () async {
                                MapHelperProvider mapHelperProvider = context
                                    .read<MapHelperProvider>();
                                context
                                        .read<SystemVariablesProvider>()
                                        .setAppCurrentState =
                                    SystemState.showSuggestedRoutes;
                                // First, stop potential edge drawings and after 40 milliseconds,
                                // there should be no follow-up drawings, making node deletion secure.
                                mapHelperProvider.setStopDrawing = true;
                                await Future.delayed(
                                  Duration(milliseconds: 40),
                                );
                                mapHelperProvider.mapWidgetController
                                    .clearLayersAndSources();
                                mapHelperProvider.setStopDrawing = false;
                              },
                            );
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(5),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Go back",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(width: 2, color: Colors.black, height: 50),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            startTraveling(context);
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(5),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Select This Route",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Used by _PreviewWindowForSuggestedPath. Builds the Row() widgets to form
/// the display
class _RouteDetailsBuilder extends StatelessWidget {
  const _RouteDetailsBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();
    List<(String, String, double)> routeDetails = buildTravelDetails(
      mapHelperProvider.getSuggestedShortestPaths,
      mapHelperProvider.getSelectedRouteId,
    );
    (double, double) fares = computeFareTotalForRoute(
      mapHelperProvider.getSuggestedShortestPaths,
      mapHelperProvider.getSelectedRouteId,
    );

    return Column(
      mainAxisSize: MainAxisSize.min, // don't force full height
      children: [
        for (final (i, (name, hexcolor, value)) in routeDetails.indexed) ...[
          if (i > 0) Container(height: 2, color: Colors.grey.shade400),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(5),
                  child: Row(
                    children: [
                      (name == "Walk")
                          ? Icon(
                              Icons.directions_walk,
                              color: hexToColor(hexcolor),
                            )
                          : ImageIcon(
                              AssetImage('assets/img/jeepney-icon.png'),
                              size: 24,
                              color: hexToColor(hexcolor),
                            ),
                      SizedBox(width: 5),
                      Flexible(
                        child: Text(name, style: TextStyle(fontSize: 20)),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(5),
                  child: Text(
                    "${(value * 100).round() / 100}m",
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              Container(color: Colors.grey.shade400, height: 2),
            ],
          ),
        ],
        Container(color: Colors.black, height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(5),
                child: Row(
                  children: [
                    ImageIcon(
                      AssetImage('assets/img/peso.png'),
                      size: 24,
                      color: Colors.black,
                    ),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text("Fare", style: TextStyle(fontSize: 20)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(5),
                child: Text(
                  "${fares.$1} php",
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(5),
                child: Row(
                  children: [
                    ImageIcon(
                      AssetImage('assets/img/peso.png'),
                      size: 24,
                      color: Colors.black,
                    ),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        "Fare (Discounted)",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(5),
                child: Text(
                  "${fares.$2} php",
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
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

/// Loads buttons that the user can use to decide what to do with the selected location.
/// The buttons will either set the source/destination values based on the long-pressed coordinates in the maplibre map.
class _SelectedLocationDecisionHelper extends StatelessWidget {
  const _SelectedLocationDecisionHelper({super.key});

  @override
  Widget build(BuildContext context) {
    SearchDetailsProvider searchDetailsProvider = context
        .read<SearchDetailsProvider>();
    SystemVariablesProvider systemVariablesProvider = context
        .read<SystemVariablesProvider>();
    MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();

    return Positioned(
      bottom: MediaQuery.sizeOf(context).height * 0.03125,
      left: MediaQuery.sizeOf(context).width * 0.125,
      right: MediaQuery.sizeOf(context).width * 0.125,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              systemVariablesProvider.setAppCurrentState =
                  SystemState.gatheringFromLoc;
              mapHelperProvider.mapWidgetController.fullRemoveSourceLayer(
                'source_selectedPoint',
                'layer_selectedPoint',
              );
              LatLng longPressedLocation =
                  searchDetailsProvider.getLongPressedLocation;
              searchDetailsProvider.getFromLocTextController.text =
                  "Selected From Map";
              mapHelperProvider.setFromLocationDetails_withLatLng(
                longPressedLocation.latitude,
                longPressedLocation.longitude,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                boxShadow: [BoxShadow(blurRadius: 3, color: Colors.black)],
              ),
              height: 50,
              child: Center(
                child: Text(
                  "Use this as your Source Location",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
          if (!mapHelperProvider.getIsFromLocationDetailsEmpty)
            SizedBox(height: 15),
          if (!mapHelperProvider.getIsFromLocationDetailsEmpty)
            GestureDetector(
              onTap: () {
                // Standard functions for setting toLocDetails
                systemVariablesProvider.setAppCurrentState =
                    SystemState.gatheringFromLoc;
                mapHelperProvider.mapWidgetController.fullRemoveSourceLayer(
                  'source_selectedPoint',
                  'layer_selectedPoint',
                );
                LatLng longPressedLocation =
                    searchDetailsProvider.getLongPressedLocation;
                searchDetailsProvider.getToLocTextController.text =
                    "Selected From Map";
                mapHelperProvider.setToLocationDetails_withLatLng(
                  longPressedLocation.latitude,
                  longPressedLocation.longitude,
                );

                systemVariablesProvider.setBackgroundWidgetVisibility = true;
                startComputingForRoutes(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  boxShadow: [BoxShadow(blurRadius: 3, color: Colors.black)],
                ),
                height: 50,
                child: Center(
                  child: Text(
                    "Use this as your Destination Location",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
          SizedBox(height: 15),
          GestureDetector(
            onTap: () {
              systemVariablesProvider.setAppCurrentState =
                  SystemState.gatheringFromLoc;
              mapHelperProvider.mapWidgetController.fullRemoveSourceLayer(
                'source_selectedPoint',
                'layer_selectedPoint',
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey,
                boxShadow: [BoxShadow(blurRadius: 3, color: Colors.black)],
              ),
              height: 50,
              child: Center(
                child: Text("Go Back", style: TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
