// ignore_for_file: non_constant_identifier_names

import 'dart:math';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/background_widget/functions.dart';
import 'package:sakenph/features/foreground_widget/functions.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/formattings.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// Widget where route details are already processed.
///
/// The one with the colored lines indicating your walk/jeep/tricycle modes
class SuggestedPathWidgetTemplate extends StatelessWidget {
  /// Index number in the iteration when the widgets are being built
  final int choice_idx;

  const SuggestedPathWidgetTemplate({required this.choice_idx});

  @override
  Widget build(BuildContext context) {
    String route_id = "result-${choice_idx + 1}";
    Map<String, dynamic> pathJSON = context
        .read<MapHelperProvider>()
        .getFilteredRouteByID(route_id);
    double travelTime = computeTravel(pathJSON, route_id);
    MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();
    (double, double) fareRates = computeFareTotalForRoute(pathJSON, route_id);

    return GestureDetector(
      onTap: () async {
        mapHelperProvider.setSelectedRouteId = route_id;
        EasyDebounce.debounce(
          DebounceId.routeSelection.toString(),
          Duration(milliseconds: 50),
          () async {
            // Draw Path
            context.read<MapHelperProvider>().mapWidgetController.drawPath(
              pathJSON,
              context,
            );

            // Zoom user to show drawn path
            context.read<MapHelperProvider>().mapWidgetController.flyToBounds(
              compileCoordsIntoLatLngList(pathJSON, route_id),
            );

            if (context.mounted) {
              context.read<SystemVariablesProvider>().setAppCurrentState =
                  SystemState.peekAtRoute;
            }
          },
        );
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
            SizedBox(height: responsiveSizeHeight(10)),
            Container(
              width: responsiveSizeHeight(
                MediaQuery.sizeOf(context).width * 0.5,
                300,
              ),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 217, 220, 223),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              height: responsiveSizeHeight(25),
              child: Center(
                child: Text(
                  "Path #${choice_idx + 1}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: responsiveSizeHeight(20),
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 217, 220, 223),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              padding: EdgeInsets.only(left: 10, right: 10),
              width: responsiveSizeWidth(MediaQuery.sizeOf(context).width),
              child: Column(
                children: [
                  SizedBox(height: responsiveSizeHeight(10)),
                  SizedBox(
                    width: responsiveSizeWidth(
                      MediaQuery.sizeOf(context).width * 0.75,
                    ),
                    child: Row(
                      children: [
                        Text(
                          "Travel Time: ",
                          style: TextStyle(fontSize: responsiveSizeHeight(20)),
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          formatSecondsToHHMMSS(travelTime),
                          style: TextStyle(
                            fontSize: responsiveSizeHeight(20),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: responsiveSizeHeight(30),
                    width: responsiveSizeHeight(
                      MediaQuery.sizeOf(context).width * 0.75,
                    ),
                    child: navPainter(pathJSON, route_id),
                  ),
                  SizedBox(
                    width: responsiveSizeWidth(
                      MediaQuery.sizeOf(context).width * 0.75,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('hh:mm a').format(DateTime.now()),
                          style: TextStyle(fontSize: responsiveSizeHeight(20)),
                        ),
                        Text(
                          DateFormat('hh:mm a').format(
                            DateTime.now().add(
                              Duration(seconds: travelTime.toInt()),
                            ),
                          ),
                          style: TextStyle(fontSize: responsiveSizeHeight(20)),
                        ),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Fare Amount: ",
                          style: TextStyle(fontSize: responsiveSizeHeight(20)),
                        ),
                        TextSpan(
                          text: "${fareRates.$1} ₱",
                          style: TextStyle(
                            fontSize: responsiveSizeHeight(20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Fare Amount (Discounted): ",
                          style: TextStyle(fontSize: responsiveSizeHeight(20)),
                        ),
                        TextSpan(
                          text: "${fareRates.$2} ₱",
                          style: TextStyle(
                            fontSize: responsiveSizeHeight(20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsiveSizeHeight(10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
