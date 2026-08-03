import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/background_widget/functions.dart';
import 'package:sakenph/features/foreground_widget/functions.dart';
import 'package:sakenph/features/foreground_widget/widgets/route_details_builder.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/formattings.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';
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
    SearchDetailsProvider searchDetailsProvider = context.read<SearchDetailsProvider>();

    String fromLocation = searchDetailsProvider.getFromLocTextController.text.isNotEmpty
        ? searchDetailsProvider.getFromLocTextController.text
        : "Your Current Location";
    String toLocation = searchDetailsProvider.getToLocTextController.text.isNotEmpty
        ? searchDetailsProvider.getToLocTextController.text
        : "Destination";

    double travelTime = computeTravel(
      mapHelperProvider.getSuggestedShortestPaths,
      mapHelperProvider.getSelectedRouteId,
    );
    (double, double) fares = computeFareTotalForRoute(
      mapHelperProvider.getSuggestedShortestPaths,
      mapHelperProvider.getSelectedRouteId,
    );
    (int, int) routeDurations = computeRouteDelay(
      mapHelperProvider.getSuggestedShortestPaths,
      mapHelperProvider.getSelectedRouteId,
    );
    int delaySeconds = routeDurations.$2 - routeDurations.$1;
    bool isDelayed = delaySeconds > 0;

    return PopScope(
      canPop:
          systemVariablesProvider.appCurrentState != SystemState.peekAtRoute,
      onPopInvokedWithResult: (didPop, result) async {
        await Future.delayed(Duration(milliseconds: 20));
        systemVariablesProvider.setAppCurrentState =
            SystemState.showSuggestedRoutes;
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
            left: responsiveSizeWidth(MediaQuery.sizeOf(context).width * 0.06),
            right: responsiveSizeWidth(
              MediaQuery.sizeOf(context).width * 0.06,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A73E8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.place,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "$fromLocation → $toLocation",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.summarize,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Route Details",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    formatSecondsToHHMMSS(travelTime),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isDelayed) ...[
                                  SizedBox(width: 6),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.warning_amber,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          "+${(delaySeconds / 60).floor()} min delay",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Route segments
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: RouteDetailsBuilder(),
                  ),

                  // Fare totals
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Divider(
                          height: 1,
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                        SizedBox(height: 10),
                        _buildFareRow(
                          label: "Regular Fare",
                          amount: fares.$1,
                          isDiscounted: false,
                        ),
                        SizedBox(height: 6),
                        _buildFareRow(
                          label: "Discounted Fare",
                          amount: fares.$2,
                          isDiscounted: true,
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),

                  // Action buttons
                  Padding(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
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
                              padding: EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    size: 18,
                                    color: Colors.grey[700],
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Go Back",
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              startTraveling(context);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Color(0xFF0D904F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.play_arrow,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Select This Route",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow({
    required String label,
    required double amount,
    required bool isDiscounted,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              isDiscounted ? Icons.local_offer : Icons.payments_outlined,
              size: 16,
              color: isDiscounted ? Colors.green : Colors.grey[600],
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          "₱${amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDiscounted ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }
}
