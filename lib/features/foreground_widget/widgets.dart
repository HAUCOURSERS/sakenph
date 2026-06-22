import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sakenph/api/nominatim.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_vars.dart';
import 'package:sakenph/pages/settings_page.dart' show SettingsPage;
import 'package:provider/provider.dart';

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
    bool isFromLocDetailsEmpty = context.select<SearchDetailsProvider, bool>(
      (value) => !value.isFromLocationDetailsEmpty,
    );
    bool hasSearchedForRoutes = context.select<SearchDetailsProvider, bool>(
      (value) => value.suggestedShortestPaths.isNotEmpty,
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
      case SystemState.confirmationForTerminatingTravel:
        // add shit here
        return Placeholder();
    }
  }
}

/// A textfield widget that is used by the user to input their origin location
class _FromLocationSearchBar extends StatelessWidget {
  const _FromLocationSearchBar();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.95,
        child: Column(
          children: [
            TextField(
              controller: context
                  .read<SearchDetailsProvider>()
                  .fromLocController,
              onChanged: (value) {
                context.read<SearchDetailsProvider>().tryToEraseLocResults(
                  SearchFieldType.from,
                );
                context.read<SearchDetailsProvider>().setTextfieldEmptyStatus(
                  value.isEmpty,
                  SearchFieldType.from,
                );
                if (value.isNotEmpty) {
                  EasyDebounce.debounce(
                    DebounceId.nominatim_fromLocationSearch.toString(),
                    Duration(seconds: 1),
                    () async {
                      context
                          .read<SearchDetailsProvider>()
                          .saveLocSearchResults(
                            await searchPlaces(value),
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
                    .setBackgroundWidgetVisibility(true);
                context.read<SystemVariablesProvider>().setAppCurrentState(
                  SystemState.gatheringFromLoc,
                );
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
                                .setBackgroundWidgetVisibility(false);
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
                                .setBackgroundWidgetVisibility(true);
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
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.95,
        child: Column(
          children: [
            TextField(
              focusNode: context.read<SearchDetailsProvider>().toLocFocusNode,
              controller: context.read<SearchDetailsProvider>().toLocController,
              onChanged: (value) {
                context.read<SearchDetailsProvider>().tryToEraseLocResults(
                  SearchFieldType.to,
                );
                context.read<SearchDetailsProvider>().setTextfieldEmptyStatus(
                  value.isEmpty,
                  SearchFieldType.to,
                );
                if (value.isNotEmpty) {
                  EasyDebounce.debounce(
                    DebounceId.nominatim_toLocationSearch.toString(),
                    Duration(seconds: 1),
                    () async {
                      context
                          .read<SearchDetailsProvider>()
                          .saveLocSearchResults(
                            await searchPlaces(value),
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
                    .setBackgroundWidgetVisibility(true);
                context.read<SystemVariablesProvider>().setAppCurrentState(
                  SystemState.gatheringToLoc,
                );
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
  const _PreviewWindowForSuggestedPath({super.key});

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
                          .setAppCurrentState(SystemState.showSuggestedRoutes);
                      context
                          .read<SearchDetailsProvider>()
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
                      // Hide every other option to focus on travelling
                      context
                          .read<SystemVariablesProvider>()
                          .setBackgroundWidgetVisibility(false);
                      context
                          .read<SystemVariablesProvider>()
                          .setAppCurrentState(
                            SystemState.isCurrentlyTravelling,
                          );

                      // Immediately set the marker
                      LatLng coords = context
                          .read<SearchDetailsProvider>()
                          .getUserCurrentGeoLoc;
                      context.read<MapHelperProvider>().shiftPosition(coords);
                      double rotation = context
                          .read<MapHelperProvider>()
                          .getMovementDirectionFromYourPositionHistory();
                      context
                          .read<SearchDetailsProvider>()
                          .mapWidgetController
                          .flyToLoc(coords);

                      await context
                          .read<SearchDetailsProvider>()
                          .mapWidgetController
                          .addUserMarker(coords, rotation);
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
  const _RouteOpenerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () {
          context.read<SystemVariablesProvider>().setAppCurrentState(
            SystemState.showSuggestedRoutes,
          );
          context.read<SystemVariablesProvider>().setBackgroundWidgetVisibility(
            true,
          );
        },
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.95,
          padding: EdgeInsets.all(20),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// DEBUG METHOD
/// WAS USED TO DOUBLE CHECK IF OFFSET CHECKING WORKS TO ENSURE THE USER ARROW
/// IS POINTING AT THE RIGHT DIRECTION
void runTestCode(BuildContext context) async {
  List<LatLng> testCoordinates = [
    LatLng(15.1209032, 120.57059900000002), // start
    LatLng(15.1244985, 120.5741943), // +500m
    LatLng(15.1280938, 120.5777896), // +1000m
    LatLng(15.1316891, 120.5813849), // +1500m
    LatLng(15.1352844, 120.5849802), // +2000m
    LatLng(15.1388797, 120.5885755), // +2500m
    LatLng(15.1424750, 120.5921708), // +3000m
    LatLng(15.1460703, 120.5957661), // +3500m
    LatLng(15.1496656, 120.5993614), // +4000m
    LatLng(15.1532609, 120.6029567), // +4500m
    LatLng(15.1568562, 120.6065520), // +5000m
    LatLng(15.1604515, 120.6101473), // +5500m
    LatLng(15.1640468, 120.6137426), // +6000m
    LatLng(15.1676421, 120.6173379), // +6500m
    LatLng(15.1712374, 120.6209332), // +7000m
    LatLng(15.1748327, 120.6245285), // +7500m
    LatLng(15.1784280, 120.6281238), // +8000m
    LatLng(15.1820233, 120.6317191), // +8500m
    LatLng(15.1856186, 120.6353144), // +9000m
    LatLng(15.1892139, 120.6389097), // +9500m
  ];

  // Capture providers before any awaits
  final mapHelper = context.read<MapHelperProvider>();
  final mapController = context
      .read<SearchDetailsProvider>()
      .mapWidgetController;

  for (LatLng coordinate in testCoordinates) {
    mapHelper.shiftPosition(coordinate);
    double rotation = mapHelper.getMovementDirectionFromYourPositionHistory();
    await mapController.addUserMarker(coordinate, rotation);
    await Future.delayed(Duration(milliseconds: 500));
  }
}

/// If the user wants to terminate their travel towards a location, select this.
class _ActiveRouteTerminator extends StatelessWidget {
  const _ActiveRouteTerminator({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            context.read<SystemVariablesProvider>().setAppCurrentState(
              SystemState.showSuggestedRoutes,
            );
            context.read<MapHelperProvider>().resetPosValues();
          },
          child: Center(
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.95,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red,
                border: Border.all(width: 1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                "Stop Tracking",
                style: TextStyle(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
