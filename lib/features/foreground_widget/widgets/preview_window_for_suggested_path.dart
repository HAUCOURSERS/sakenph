import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/foreground_widget/functions.dart';
import 'package:sakenph/features/foreground_widget/widgets/route_details_builder.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/system/permissions.dart'
    show handleLocationPermission;
import 'package:sakenph/globals/functions/formattings.dart';
import 'package:sakenph/globals/functions/route_timing.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// When the user selects a path from the suggested paths display, the widgets
/// that will show up will come from this.
///
/// Includes the go back, select route, walk details and total fare from transportation
/// methods.
class PreviewWindowForSuggestedPath extends StatefulWidget {
  final Map<String, dynamic> routeDetails;

  const PreviewWindowForSuggestedPath({super.key, required this.routeDetails});

  @override
  State<PreviewWindowForSuggestedPath> createState() =>
      _PreviewWindowForSuggestedPathState();
}

class _PreviewWindowForSuggestedPathState
    extends State<PreviewWindowForSuggestedPath> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemVariablesProvider systemVariablesProvider = context
        .read<SystemVariablesProvider>();
    MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();
    SearchDetailsProvider searchDetailsProvider = context
        .read<SearchDetailsProvider>();

    String fromLocation =
        searchDetailsProvider.getFromLocTextController.text.isNotEmpty
        ? searchDetailsProvider.getFromLocTextController.text
        : "Your Current Location";
    String toLocation =
        searchDetailsProvider.getToLocTextController.text.isNotEmpty
        ? searchDetailsProvider.getToLocTextController.text
        : "Destination";

    final routeTiming = computeRouteTiming(
      mapHelperProvider.getSuggestedShortestPaths,
      mapHelperProvider.getSelectedRouteId,
    );
    double travelTime = routeTiming.actualSeconds.toDouble();
    (double, double) fares = computeFareTotalForRoute(
      mapHelperProvider.getSuggestedShortestPaths,
      mapHelperProvider.getSelectedRouteId,
    );
    int delaySeconds = routeTiming.delaySeconds;
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
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsiveSizeWidth(MediaQuery.sizeOf(context).width * 0.06),
                0,
                responsiveSizeWidth(MediaQuery.sizeOf(context).width * 0.06),
                responsiveSizeHeight(
                  MediaQuery.sizeOf(context).height * 0.03125,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: 0.62,
                  minChildSize: 0.14,
                  maxChildSize: 0.62,
                  snap: true,
                  snapSizes: const [0.14, 0.4, 0.62],
                  expand: false,
                  builder: (context, scrollController) {
                    return Container(
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
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    // Keep the sheet header fixed; the route
                                    // list below owns its scrolling area.
                                    if (notification.depth == 0 &&
                                        notification.metrics.pixels > 0) {
                                      scrollController.jumpTo(0);
                                    }
                                    return false;
                                  },
                                  child: SingleChildScrollView(
                                    controller: scrollController,
                                    // Sheet movement is controlled only by the
                                    // blue handle; route details scroll below.
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onVerticalDragUpdate: (details) =>
                                              _moveSheetBy(
                                                context,
                                                details.delta.dy,
                                              ),
                                          child: Container(
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
                                                GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onVerticalDragUpdate: (details) {
                                                    if (!_sheetController
                                                        .isAttached) {
                                                      return;
                                                    }
                                                    final nextSize =
                                                        (_sheetController.size -
                                                                details
                                                                        .delta
                                                                        .dy /
                                                                    MediaQuery.sizeOf(
                                                                      context,
                                                                    ).height)
                                                            .clamp(0.14, 0.62)
                                                            .toDouble();
                                                    _sheetController.jumpTo(
                                                      nextSize,
                                                    );
                                                  },
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 8,
                                                          ),
                                                      child: Center(
                                                        child: Container(
                                                          width: 56,
                                                          height: 5,
                                                          decoration: BoxDecoration(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.75,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  3,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  width: double.infinity,
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
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
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
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
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 16,
                                                          color: Colors.white,
                                                          letterSpacing: 0.3,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.2,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            formatSecondsToHHMMSS(
                                                              travelTime,
                                                            ),
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                        if (isDelayed) ...[
                                                          SizedBox(width: 6),
                                                          Container(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 3,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Color(
                                                                    0xFFDC2626,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12,
                                                                      ),
                                                                ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .warning_amber,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 12,
                                                                ),
                                                                SizedBox(
                                                                  width: 3,
                                                                ),
                                                                Text(
                                                                  "+${(delaySeconds / 60).floor()} min delay",
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
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
                                        ),

                                        // Route segments
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          child: RouteDetailsBuilder(),
                                        ),

                                        _buildFareDisclaimer(),

                                        // Fare totals
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Column(
                                            children: [
                                              Divider(
                                                height: 1,
                                                color: Colors.grey.withValues(
                                                  alpha: 0.2,
                                                ),
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
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _buildActionButtons(context),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  EasyDebounce.debounce(
                    DebounceId.routeSelection.toString(),
                    const Duration(milliseconds: 40),
                    () async {
                      final mapHelperProvider = context
                          .read<MapHelperProvider>();
                      context
                              .read<SystemVariablesProvider>()
                              .setAppCurrentState =
                          SystemState.showSuggestedRoutes;
                      mapHelperProvider.setStopDrawing = true;
                      await Future.delayed(const Duration(milliseconds: 40));
                      mapHelperProvider.mapWidgetController
                          .clearLayersAndSources();
                      mapHelperProvider.setStopDrawing = false;
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: 18, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Go Back',
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
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () async {
                  bool locationSet = await handleLocationPermission(context);
                  if (locationSet) {
                      startTraveling(context);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D904F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, size: 20, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Select This Route',
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
    );
  }

  Widget _buildFareDisclaimer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Semantics(
        label:
            'Fare estimate based on LTFRB and PTRO Angeles City fare matrices. Actual fares may vary.',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F6FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD9E2EC)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 15, color: Color(0xFF52606D)),
              SizedBox(width: 7),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: Color(0xFF364152),
                      fontSize: 11,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(text: 'Fare estimate based on '),
                      TextSpan(
                        text: 'LTFRB/PTRO Angeles City',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' fare matrices. Actual fares may vary.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _moveSheetBy(BuildContext context, double deltaY) {
    if (!_sheetController.isAttached) return;
    final nextSize =
        (_sheetController.size - deltaY / MediaQuery.sizeOf(context).height)
            .clamp(0.14, 0.62)
            .toDouble();
    _sheetController.jumpTo(nextSize);
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
            Text.rich(
              TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  if (isDiscounted)
                    const TextSpan(
                      text: " (Student/Senior/PWD)",
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 10,
                        color: Color.fromARGB(255, 59, 59, 59),
                      ),
                    ),
                ],
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
