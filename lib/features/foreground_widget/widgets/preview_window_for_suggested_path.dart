import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/foreground_widget/functions.dart';
import 'package:sakenph/features/foreground_widget/widgets/route_details_builder.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// When the user selects a path from the suggested paths display, the widgets
/// that will show up will come from this.
///
/// Includes the go back, select route, walk details and total fare from transportation
/// methods.
class PreviewWindowForSuggestedPath extends StatelessWidget {
  final Map<String, dynamic> routeDetails;

  const PreviewWindowForSuggestedPath({super.key, required this.routeDetails});

  @override
  Widget build(BuildContext context) {
    SystemVariablesProvider systemVariablesProvider = context
        .read<SystemVariablesProvider>();
    MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();
    return PopScope(
      canPop:
          systemVariablesProvider.appCurrentState != SystemState.peekAtRoute,
      onPopInvokedWithResult: (didPop, result) async {
        await Future.delayed(Duration(milliseconds: 20));
        systemVariablesProvider.setAppCurrentState =
            SystemState.showSuggestedRoutes;
        // First, stop potential edge drawings and after 40 milliseconds,
        // there should be no follow-up drawings, making node deletion secure.
        mapHelperProvider.setStopDrawing = true;
        await Future.delayed(Duration(milliseconds: 40));
        mapHelperProvider.mapWidgetController.clearLayersAndSources();
        mapHelperProvider.setStopDrawing = false;
      },
      child: Stack(
        children: [
          Positioned(
            bottom: responsiveSizeHeight(
              MediaQuery.sizeOf(context).height * 0.03125,
            ),
            left: responsiveSizeWidth(MediaQuery.sizeOf(context).width * 0.125),
            right: responsiveSizeWidth(
              MediaQuery.sizeOf(context).width * 0.125,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.all(Radius.circular(5)),
              ),
              child: Column(
                children: [
                  Container(
                    height: responsiveSizeHeight(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5),
                      ),
                    ),
                  ),

                  Container(
                    color: Colors.black,
                    height: responsiveSizeHeight(2),
                  ),
                  RouteDetailsBuilder(),
                  Container(
                    width: double.infinity,
                    color: Colors.black,
                    height: responsiveSizeHeight(2),
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
                            height: responsiveSizeHeight(50),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(
                                  responsiveSizeHeight(5),
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Go back",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: responsiveSizeHeight(20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: responsiveSizeWidth(2),
                        color: Colors.black,
                        height: responsiveSizeHeight(50),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            startTraveling(context);
                          },
                          child: Container(
                            height: responsiveSizeHeight(50),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(
                                  responsiveSizeHeight(5),
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Select This Route",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: responsiveSizeHeight(20),
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
