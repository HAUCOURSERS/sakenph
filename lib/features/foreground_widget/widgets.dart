import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:sakenph/api/nominatim.dart';
import 'package:sakenph/features/foreground_widget/functions.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_tasks.dart';
import 'package:sakenph/providers/provider_system_vars.dart';
import 'package:sakenph/pages/settings_page.dart' show SettingsPage;
import 'package:provider/provider.dart';

import '../../providers/provider_map_helper.dart';

/// Added to import the backend service to use its functions for querying shortest paths and fetching jeepney routes.
import 'package:sakenph/classes/jeepney_route.dart';

/// The main widget for the Foreground. Any widgets that are needed to be displayed
/// at the top of the main widget's stack is written here.
class ForegroundWidget extends StatefulWidget {
  const ForegroundWidget({super.key});

  @override
  State<ForegroundWidget> createState() => _ForegroundWidgetState();
}

// class _ForegroundWidgetState extends State<ForegroundWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Stack(children: [_ForegroundWidgetContentRenderer()]),
//     );
//   }
// }

// Added to import the backend service to use its functions for querying shortest paths and fetching jeepney routes.
class _ForegroundWidgetState extends State<ForegroundWidget> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          _ForegroundWidgetContentRenderer(),
          JeepneyRouteFloatingControl(),
        ],
      ),
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
                  .getFromLocTextController,
              onChanged: (value) {
                context.read<SearchDetailsProvider>().tryToEraseLocResults(
                  SearchFieldType.from,
                );
                context
                        .read<SearchDetailsProvider>()
                        .setActiveSearching_fromLoc =
                    value.isNotEmpty;
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
              focusNode: context
                  .read<SearchDetailsProvider>()
                  .getToLocFocusNode,
              controller: context
                  .read<SearchDetailsProvider>()
                  .getToLocTextController,
              onChanged: (value) {
                context.read<SearchDetailsProvider>().tryToEraseLocResults(
                  SearchFieldType.to,
                );
                context.read<SearchDetailsProvider>().setActiveSearching_toLoc =
                    value.isNotEmpty;
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

/// If the user wants to terminate their travel towards a location, select this.
class _ActiveRouteTerminator extends StatelessWidget {
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
            /*
            context
                .read<MapHelperProvider>()
                .mapWidgetController
                .clearLayersAndSources();*/
            context.read<SystemTasksProvder>().stop_repeatingTask();
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

/// A floating button that can be dragged around the screen.
/// When pressed, it opens a panel that shows the list of jeepney routes and their visibility status on the map.
class JeepneyRouteFloatingControl extends StatefulWidget {
  const JeepneyRouteFloatingControl({super.key});

  @override
  State<JeepneyRouteFloatingControl> createState() =>
      _JeepneyRouteFloatingControlState();
}

class _JeepneyRouteFloatingControlState
    extends State<JeepneyRouteFloatingControl> {
  bool _isOpen = false;
  Offset _position = const Offset(0, 120);

  @override
  Widget build(BuildContext context) {
    final routes = context.select<MapHelperProvider, List<JeepneyRoute>>(
      (provider) => provider.jeepneyRoutes,
    );

    final visibleIds = context.select<MapHelperProvider, Set<String>>(
      (provider) => provider.visibleJeepneyRouteIds,
    );

    final isLoading = context.select<MapHelperProvider, bool>(
      (provider) => provider.isLoadingJeepneyRoutes,
    );

  final screenSize = MediaQuery.sizeOf(context);
  final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
  const buttonSize = 54.0;
  const panelWidth = 280.0;

  final defaultX = screenSize.width - buttonSize - 16;
  final currentX = _position.dx == 0 ? defaultX : _position.dx;
  final currentY = _position.dy;

  final clampedX = currentX.clamp(8.0, screenSize.width - buttonSize - 8);
  final clampedY = currentY.clamp(
    90.0,
    screenSize.height - buttonSize - bottomSafeArea - 100, 
    // 100 is a buffer to avoid overlapping with the bottom navigation bar
  );

    final panelLeft = (clampedX - panelWidth + buttonSize).clamp(
      8.0,
      screenSize.width - panelWidth - 8,
    );

    return Stack(
      children: [
        if (_isOpen)
          Positioned(
            left: panelLeft,
            top: clampedY + buttonSize + 8,
            child: _JeepneyRouteDropdownPanel(
              routes: routes,
              visibleIds: visibleIds,
              isLoading: isLoading,
            ),
          ),
        Positioned(
          left: clampedX,
          top: clampedY,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position = Offset(
                  clampedX + details.delta.dx,
                  clampedY + details.delta.dy,
                );
              });
            },
            onTap: () {
              setState(() {
                _isOpen = !_isOpen;
              });
            },
            child: Material(
              color: const Color.fromARGB(255, 41, 114, 110),
              shape: const CircleBorder(),
              elevation: 5,
              child: SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: Icon(
                  _isOpen ? Icons.close : Icons.alt_route,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A panel that displays a list of jeepney routes with checkboxes to toggle their visibility on the map.
class _JeepneyRouteDropdownPanel extends StatelessWidget {
  final List<JeepneyRoute> routes;
  final Set<String> visibleIds;
  final bool isLoading;

  const _JeepneyRouteDropdownPanel({
    required this.routes,
    required this.visibleIds,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCount = visibleIds.length;

    return Material(
      color: Colors.white,
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 280,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: isLoading
              ? const SizedBox(
                  height: 90,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Jeepney Routes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          '$visibleCount/${routes.length}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text('Show'),
                            onPressed: () {
                              context
                                  .read<MapHelperProvider>()
                                  .showAllJeepneyRoutes();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.visibility_off, size: 18),
                            label: const Text('Hide'),
                            onPressed: () {
                              context
                                  .read<MapHelperProvider>()
                                  .hideAllJeepneyRoutes();
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (routes.isEmpty)
                      const SizedBox(
                        height: 70,
                        child: Center(
                          child: Text(
                            'No routes loaded',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 260),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: routes.length,
                          itemBuilder: (context, index) {
                            final route = routes[index];
                            final isVisible = visibleIds.contains(route.id);

                            return CheckboxListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding: EdgeInsets.zero,
                              value: isVisible,
                              secondary: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Color(
                                    int.parse(
                                      route.color.replaceFirst('#', '0xff'),
                                    ),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(
                                route.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                              onChanged: (_) {
                                context
                                    .read<MapHelperProvider>()
                                    .toggleJeepneyRoute(route);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}