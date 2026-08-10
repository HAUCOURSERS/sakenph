import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/api/backend_service.dart';
import 'package:sakenph/features/background_widget/functions.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// Loads buttons that the user can use to decide what to do with the selected location.
/// The buttons will either set the source/destination values based on the long-pressed coordinates in the maplibre map.
class SelectedLocationDecisionHelper extends StatelessWidget {
  const SelectedLocationDecisionHelper({super.key});

  @override
  Widget build(BuildContext context) {
    SearchDetailsProvider searchDetailsProvider = context
        .read<SearchDetailsProvider>();
    SystemVariablesProvider systemVariablesProvider = context
        .read<SystemVariablesProvider>();
    MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (systemVariablesProvider.appCurrentState ==
                SystemState.confirmingLocationSelection) {
              systemVariablesProvider.setAppCurrentState =
                  SystemState.gatheringFromLoc;
              mapHelperProvider.mapWidgetController.fullRemoveSourceLayer(
                'source_selectedPoint',
                'layer_selectedPoint',
              );
            }
          },
          child: PopScope(
            canPop:
                systemVariablesProvider.appCurrentState !=
                SystemState.confirmingLocationSelection,
            onPopInvokedWithResult: (didPop, result) async {
              if (systemVariablesProvider.appCurrentState ==
                  SystemState.confirmingLocationSelection) {
                systemVariablesProvider.setBackgroundWidgetVisibility = false;
                systemVariablesProvider.setAppCurrentState =
                    SystemState.gatheringFromLoc;
              }
            },
            child: Container(
              color: Colors.transparent,
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
            ),
          ),
        ),
        Center(
          child: SizedBox(
            width: responsiveSizeWidth(400, 700),
            height: MediaQuery.sizeOf(context).height,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      systemVariablesProvider.setAppCurrentState =
                          SystemState.gatheringFromLoc;
                      mapHelperProvider.mapWidgetController
                          .fullRemoveSourceLayer(
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
                        boxShadow: [
                          BoxShadow(blurRadius: 3, color: Colors.black),
                        ],
                      ),
                      height: responsiveSizeHeight(50),
                      child: Center(
                        child: Text(
                          "Use this as your Source Location",
                          style: TextStyle(fontSize: responsiveSizeHeight(20)),
                        ),
                      ),
                    ),
                  ),
                  if (!mapHelperProvider.getIsFromLocationDetailsEmpty)
                    SizedBox(height: responsiveSizeHeight(15)),
                  if (!mapHelperProvider.getIsFromLocationDetailsEmpty)
                    GestureDetector(
                      onTap: () {
                        // Standard functions for setting toLocDetails
                        systemVariablesProvider.setAppCurrentState =
                            SystemState.gatheringFromLoc;
                        mapHelperProvider.mapWidgetController
                            .fullRemoveSourceLayer(
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

                        systemVariablesProvider.setBackgroundWidgetVisibility =
                            true;
                        startComputingForRoutes(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          boxShadow: [
                            BoxShadow(blurRadius: 3, color: Colors.black),
                          ],
                        ),
                        height: responsiveSizeHeight(50),
                        child: Center(
                          child: Text(
                            "Use this as your Destination Location",
                            style: TextStyle(
                              fontSize: responsiveSizeHeight(20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: responsiveSizeHeight(15)),
                  GestureDetector(
                    onTap: () {
                      systemVariablesProvider.setAppCurrentState =
                          SystemState.gatheringFromLoc;
                      mapHelperProvider.mapWidgetController
                          .fullRemoveSourceLayer(
                            'source_selectedPoint',
                            'layer_selectedPoint',
                          );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        boxShadow: [
                          BoxShadow(blurRadius: 3, color: Colors.black),
                        ],
                      ),
                      height: responsiveSizeHeight(50),
                      child: Center(
                        child: Text(
                          "Go Back",
                          style: TextStyle(fontSize: responsiveSizeHeight(20)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
