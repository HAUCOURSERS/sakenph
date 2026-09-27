import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/api/backend_service.dart';
import 'package:sakenph/features/background_widget/functions.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_data.dart';
import 'package:sakenph/providers/provider_system_vars.dart';
import 'package:sakenph/providers/provider_tutorial_mechanics.dart';

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
    SystemDataProvider systemDataProvider = context.read<SystemDataProvider>();
    TutorialMechanicsProvider tutorialMechanicsProvider = context
        .read<TutorialMechanicsProvider>();

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
                await mapHelperProvider.mapWidgetController
                    .fullRemoveSourceLayer(
                      'source_selectedPoint',
                      'layer_selectedPoint',
                    );
              }
            },
            child: SizedBox(
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
                    onTap: () async {
                      searchDetailsProvider.setHasObtainedFromLocAtLeastOnce =
                          true;
                      if (systemDataProvider.isTutorialOngoing) {
                        tutorialMechanicsProvider.moveToStage14();
                      }
                      // for special behavior in unique inputs
                      searchDetailsProvider.setIsInputSpecial_fromLoc = true;
                      // wipes the text so the hint text shows up
                      searchDetailsProvider.getFromLocTextController.text = "";
                      // sets the hint text
                      searchDetailsProvider.setFromLocTextfieldHintText =
                          "Selected From Map";
                      // to prevent odd behavior related to the autofill
                      searchDetailsProvider.tryToEraseLocResults(
                        SearchFieldType.from,
                      );
                      // putting the system state to default
                      systemVariablesProvider.setAppCurrentState =
                          SystemState.gatheringFromLoc;
                      // to prevent unwanted visible view of the search results field
                      searchDetailsProvider.setActiveSearching_fromLoc = false;
                      await mapHelperProvider.mapWidgetController
                          .fullRemoveSourceLayer(
                            'source_selectedPoint',
                            'layer_selectedPoint',
                          );
                      LatLng longPressedLocation =
                          searchDetailsProvider.getLongPressedLocation;
                      searchDetailsProvider.getFromLocTextController.text = "";
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
                  if (searchDetailsProvider.hasObtainedFromLocAtLeastOnce)
                    SizedBox(height: responsiveSizeHeight(15)),
                  if (searchDetailsProvider.hasObtainedFromLocAtLeastOnce)
                    GestureDetector(
                      onTap: () async {
                        if (systemDataProvider.isTutorialOngoing) {
                          tutorialMechanicsProvider.moveToStage16();
                        }

                        /// Standard functions for setting toLocDetails
                        // for special behavior in unique inputs
                        searchDetailsProvider.setIsInputSpecial_toLoc = true;
                        // wipes the text so the hint text shows up
                        searchDetailsProvider.getToLocTextController.text = "";
                        // sets the hint text
                        searchDetailsProvider.setToLocTextfieldHintText =
                            "Selected From Map";
                        // to prevent odd behavior related to the autofill
                        searchDetailsProvider.tryToEraseLocResults(
                          SearchFieldType.to,
                        );
                        // putting the system state to default
                        systemVariablesProvider.setAppCurrentState =
                            SystemState.gatheringFromLoc;
                        // to prevent unwanted visible view of the search results field
                        searchDetailsProvider.setActiveSearching_toLoc = false;
                        await mapHelperProvider.mapWidgetController
                            .fullRemoveSourceLayer(
                              'source_selectedPoint',
                              'layer_selectedPoint',
                            );
                        LatLng longPressedLocation =
                            searchDetailsProvider.getLongPressedLocation;
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
                      // return to the default systemstate since it's just going back
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
