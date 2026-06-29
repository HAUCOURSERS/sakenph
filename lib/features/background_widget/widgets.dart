import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart'
    show LoadingAnimationWidget;
import 'package:provider/provider.dart';
import 'package:sakenph/classes/nominatim_response.dart';
import 'package:sakenph/features/background_widget/functions.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// This widget is used to hide the map and to show its contents. Contents depend
/// on [SystemVariablesProvider.appCurrentState] current value.
class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    bool backgroundWidgetVisibility = context
        .select<SystemVariablesProvider, bool>(
          (val) => val.backgroundWidgetVisibility,
        );
    SystemState currentSystemState = context
        .select<SystemVariablesProvider, SystemState>(
          (val) => val.appCurrentState,
        );
    Color backgroundWidgetColor = context
        .select<SystemVariablesProvider, Color>(
          (value) => value.backgroundWidgetColor,
        );
    return IgnorePointer(
      ignoring: !backgroundWidgetVisibility,
      child: AnimatedOpacity(
        opacity: backgroundWidgetVisibility ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,

          /// The intention for this is that if the user presses anywhere in the
          /// background widget, it would hide it. Think of it as a way to help
          /// users easily close down the background widget
          ///
          /// However the app may go into a state where its peeking at the selected route.
          /// During this time, the auto hide will be disabled.
          onTap: () {
            if (currentSystemState != SystemState.peekAtRoute) {
              context
                  .read<SystemVariablesProvider>()
                  .setBackgroundWidgetVisibility(false);
            }
          },
          child: PopScope(
            canPop: !context
                .read<SystemVariablesProvider>()
                .backgroundWidgetVisibility,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                context
                    .read<SystemVariablesProvider>()
                    .setBackgroundWidgetVisibility(false);
              }
            },
            child: Container(
              color: backgroundWidgetColor,
              child: _BackgroundWidgetContentRenderer(
                currentSystemState: currentSystemState,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Relies on the value of [SystemVariablesProvider.appCurrentState] to
/// decide what to render.
class _BackgroundWidgetContentRenderer extends StatelessWidget {
  final SystemState currentSystemState;

  const _BackgroundWidgetContentRenderer({required this.currentSystemState});

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (currentSystemState) {
      case SystemState.gatheringFromLoc:
        child = ViewForRequestingFromLocation();
        break;
      case SystemState.gatheringToLoc:
        child = _ViewForRequestingToLocation();
        break;
      case SystemState.waitingForBackendResponse:
        child = _WaitingForBackendResponse();
        break;
      case SystemState.showSuggestedRoutes:
        child = _DisplaySuggestedPaths();
        break;
      case SystemState.peekAtRoute:
      case SystemState.hideWidgets:
      case SystemState.isCurrentlyTravelling:
      case SystemState.confirmationForTerminatingTravel:
        child = SizedBox.shrink();
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(key: ValueKey(currentSystemState), child: child),
    );
  }
}

/// Widget to use when you're requesting for the user's origin destination. Contains
/// a button that will get the user's current location and suggestions from their
/// inputs.
class ViewForRequestingFromLocation extends StatelessWidget {
  const ViewForRequestingFromLocation({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isFromLocResultsEmpty = context
        .select<SearchDetailsProvider, bool>(
          (value) => value.getFromLocSearchResults.isEmpty,
        );
    final bool isTextfieldEmpty = context.select<SearchDetailsProvider, bool>(
      (value) => value.isFromLocTextfieldEmpty,
    );

    /// For building the choices in places
    Widget toShowSuggestionResults = isFromLocResultsEmpty
        ? Column(
            children: [
              SizedBox(height: 70),
              Align(
                child: LoadingAnimationWidget.discreteCircle(
                  color: Colors.black,
                  size: 100,
                ),
              ),
            ],
          )
        : Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) => _SearchResultRenderer(
                searchFieldType: SearchFieldType.from,
                nomiPlace: context
                    .read<SearchDetailsProvider>()
                    .getFromLocSearchResults[index],
              ),
              itemCount: context
                  .read<SearchDetailsProvider>()
                  .getFromLocSearchResults
                  .length,
            ),
          );

    return Column(
      children: [
        SizedBox(height: 60),
        if (context.read<MapHelperProvider>().getIsFromLocationDetailsEmpty)
          SizedBox(height: 60),
        _UseCurrentLocationButton(),
        SizedBox(height: 10),
        if (!isTextfieldEmpty) toShowSuggestionResults,
      ],
    );
  }
}

/// When pressed, it will get the user's current location and passes it to [SystemVariablesProvider]
/// as origin location reference.
///
/// Stateful Widget is used to add color change tap animation
class _UseCurrentLocationButton extends StatefulWidget {
  @override
  State<_UseCurrentLocationButton> createState() =>
      _UseCurrentLocationButtonState();
}

class _UseCurrentLocationButtonState extends State<_UseCurrentLocationButton> {
  bool _showColor = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        color: _showColor ? Colors.grey.shade300 : Colors.transparent,
        child: GestureDetector(
          onTap: () async {
            setState(() {
              _showColor = true;
            });
            context.read<MapHelperProvider>().useCurrentUserGeoLocAsOrigin(
              context,
            );
            context.read<SystemVariablesProvider>().setAppCurrentState(
              SystemState.gatheringToLoc,
            );
            context
                .read<SearchDetailsProvider>()
                .requestFocusTowardsLocTextfield();

            context.read<SearchDetailsProvider>().setFromLocTextfieldText =
                "Your Current Location";
            await Future.delayed(Duration(milliseconds: 100));
            setState(() {
              _showColor = false;
            });
          },
          child: Container(
            width: MediaQuery.sizeOf(context).width * 0.9,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.0),
            ),
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(Icons.location_on),
                Text(
                  "Press to use your location",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewForRequestingToLocation extends StatelessWidget {
  const _ViewForRequestingToLocation({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isToLocResultsEmpty = context
        .select<SearchDetailsProvider, bool>(
          (value) => value.getToLocSearchResults.isEmpty,
        );
    final bool isTextfieldEmpty = context.select<SearchDetailsProvider, bool>(
      (value) => value.isToLocTextfieldEmpty,
    );

    /// For building the choices in places
    Widget toShowSuggestionResults = isToLocResultsEmpty
        ? Column(
            children: [
              SizedBox(height: 70),
              Align(
                child: LoadingAnimationWidget.discreteCircle(
                  color: Colors.black,
                  size: 100,
                ),
              ),
            ],
          )
        : Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) => _SearchResultRenderer(
                searchFieldType: SearchFieldType.to,
                nomiPlace: context
                    .read<SearchDetailsProvider>()
                    .getToLocSearchResults[index],
              ),
              itemCount: context
                  .read<SearchDetailsProvider>()
                  .getToLocSearchResults
                  .length,
            ),
          );

    return SizedBox(
      height: MediaQuery.sizeOf(context).height,
      width: double.infinity,
      child: Column(
        children: [
          SizedBox(height: 110),
          SizedBox(height: 10),
          if (!isTextfieldEmpty) toShowSuggestionResults,
        ],
      ),
    );
  }
}

/// Takes in information of a [NominatimPlace] object and creates a widget for
/// ListView out of it.
///
/// Can be reused if needed
class _SearchResultRenderer extends StatefulWidget {
  final NominatimPlace nomiPlace;
  final SearchFieldType searchFieldType;

  const _SearchResultRenderer({
    required this.nomiPlace,
    required this.searchFieldType,
  });

  @override
  State<_SearchResultRenderer> createState() => _SearchResultRendererState();
}

class _SearchResultRendererState extends State<_SearchResultRenderer> {
  /// Used alongside AnimatedContainer to show a tapping color effect
  bool _showColor = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      color: _showColor ? Colors.grey.shade400 : Colors.transparent,
      duration: Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: () async {
          if (widget.nomiPlace.name != "No Places Found") {
            MapHelperProvider mapHelperProvider = context
                .read<MapHelperProvider>();
            SystemVariablesProvider systemVariablesProvider = context
                .read<SystemVariablesProvider>();
            SearchDetailsProvider searchDetailsProvider = context
                .read<SearchDetailsProvider>();
            switch (widget.searchFieldType) {
              case SearchFieldType.from:
                mapHelperProvider.setFromLocationDetails = widget.nomiPlace;
                systemVariablesProvider.setAppCurrentState(
                  SystemState.gatheringToLoc,
                );
                searchDetailsProvider.setFromLocTextfieldText =
                    widget.nomiPlace.name;
                searchDetailsProvider.requestFocusTowardsLocTextfield();
                break;
              case SearchFieldType.to:
                mapHelperProvider.setToLocationDetails = widget.nomiPlace;
                startComputingForRoutes(context);
                searchDetailsProvider.setToLocTextfieldText =
                    widget.nomiPlace.name;
                searchDetailsProvider.unfocusFromLocTextfield();
                break;
            }
          }
          setState(() {
            _showColor = true;
          });
          await Future.delayed(Duration(milliseconds: 50));
          setState(() {
            _showColor = false;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
          ),
          child: ListTile(
            title: Row(
              children: [
                Icon(Icons.location_on),
                SizedBox(width: 10, height: 0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nomiPlace.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.nomiPlace.displayName,
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stand-in widget for when the app waits for backend response
class _WaitingForBackendResponse extends StatefulWidget {
  @override
  State<_WaitingForBackendResponse> createState() =>
      __WaitingForBackendResponseState();
}

class __WaitingForBackendResponseState
    extends State<_WaitingForBackendResponse> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      height: MediaQuery.sizeOf(context).height,
      child: Center(
        child: LoadingAnimationWidget.fourRotatingDots(
          color: Colors.grey,
          size: 150,
        ),
      ),
    );
  }
}

/// Widget that will display route choices given by backend
class _DisplaySuggestedPaths extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Meant to absorb onTap hits to prevent closure due to the main background
    // widget's nature
    return GestureDetector(
      child: Stack(
        children: [
          Container(
            color: Colors.transparent,
            alignment: Alignment.center,
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
            child: Center(child: _SuggestedPathWidgetListBuilder()),
          ),
          Positioned(
            top: 120,
            left: MediaQuery.sizeOf(context).width * 0.125,
            right: MediaQuery.sizeOf(context).width * 0.125,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black, width: 1),
                // black outline
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 3), // shadow goes downward
                  ),
                ],
              ),
              child: Text(
                "Tap to view path",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black, fontSize: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Builder of the widget list that contains suggested paths.
///
/// This widget is just a SizedBox that handles ListView.separated() operations
/// to form the interactable route widgets.
class _SuggestedPathWidgetListBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> shortestPaths = context
        .read<MapHelperProvider>()
        .getSuggestedShortestPaths["routes"];
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.8,
      child: ListView.separated(
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return _SuggestedPathWidgetTemplate(choice_idx: index);
        },
        separatorBuilder: (context, index) => SizedBox(height: 15),
        itemCount: shortestPaths.length,
      ),
    );
  }
}

/// Widget where route details are already processed.
///
/// The one with the colored lines indicating your walk/jeep/tricycle modes
class _SuggestedPathWidgetTemplate extends StatelessWidget {
  /// Index number in the iteration when the widgets are being built
  final int choice_idx;

  const _SuggestedPathWidgetTemplate({super.key, required this.choice_idx});

  @override
  Widget build(BuildContext context) {
    String route_id = "result-${choice_idx + 1}";
    Map<String, dynamic> pathJSON = context
        .read<MapHelperProvider>()
        .getFilteredRouteByID(route_id);
    double travelTime = computeTravel(pathJSON, route_id);

    return GestureDetector(
      onTap: () async {
        // Draw Path
        context.read<MapHelperProvider>().mapWidgetController.drawPath(
          pathJSON,
        );

        // Zoom user to show drawn path
        context.read<MapHelperProvider>().mapWidgetController.flyToBounds(
          compileCoordsIntoLatLngList(pathJSON, route_id),
        );

        // Add a short delay to make the transition extra smooth
        await Future.delayed(Duration(milliseconds: 50));
        if (context.mounted) {
          context.read<SystemVariablesProvider>().setAppCurrentState(
            SystemState.peekAtRoute,
          );
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(height: 10),
            Container(
              width: MediaQuery.sizeOf(context).width * 0.5,
              padding: EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 217, 220, 223),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              height: 30,
              child: Text(
                "Path #${choice_idx + 1}",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 217, 220, 223),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              height: 120,
              width: MediaQuery.sizeOf(context).width,
              child: Column(
                children: [
                  SizedBox(height: 10),
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width * 0.75,
                    child: Row(
                      children: [
                        Text(
                          "Travel Time: ",
                          style: TextStyle(fontSize: 20),
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          formatSecondsToHHMMSS(travelTime),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 30,
                    width: MediaQuery.sizeOf(context).width * 0.75,
                    child: navPainter(pathJSON, route_id),
                  ),
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width * 0.75,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('hh:mm a').format(DateTime.now()),
                          style: TextStyle(fontSize: 20),
                        ),
                        Text(
                          DateFormat('hh:mm a').format(
                            DateTime.now().add(
                              Duration(seconds: travelTime.toInt()),
                            ),
                          ),
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
