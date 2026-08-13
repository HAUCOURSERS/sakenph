// ignore_for_file: non_constant_identifier_names

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/background_widget/functions.dart';
import 'package:sakenph/features/foreground_widget/functions.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/formattings.dart';
import 'package:sakenph/globals/functions/route_timing.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// Widget where route details are already processed.
///
/// The one with the colored lines indicating your walk/jeep/tricycle modes
class SuggestedRouteWidgetTemplate extends StatelessWidget {
  /// Index number in the iteration when the widgets are being built
  final int choice_idx;

  /// Stable route ID from the backend, independent of display order.
  final String route_id;

  /// Distinct colors for each path header (different from badge colors)
  static const List<Color> _pathColors = [
    Color(0xFF6750A4), // Path #1 - Purple
    Color(0xFF0D9488), // Path #2 - Teal
    Color(0xFFC2410C), // Path #3 - Deep Orange
    Color(0xFF7C3AED), // Path #4 - Violet
    Color(0xFF0369A1), // Path #5 - Sky Blue
  ];

  const SuggestedRouteWidgetTemplate({
    required this.choice_idx,
    required this.route_id,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> pathJSON = context
        .read<MapHelperProvider>()
        .getFilteredRouteByID(route_id);
    final routeTiming = computeRouteTiming(pathJSON, route_id);
    double travelTime = routeTiming.actualSeconds.toDouble();
    MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();
    (double, double) fareRates = computeFareTotalForRoute(pathJSON, route_id);
    Set<String> badges = computeRouteBadges(
      mapHelperProvider.getSuggestedShortestPaths,
      route_id,
    );
    int delaySeconds = routeTiming.delaySeconds;
    bool isDelayed = delaySeconds > 0;

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
            // Header with path number
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _pathColors[choice_idx % _pathColors.length],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.route, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Path #${choice_idx + 1}",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (choice_idx == 0) ...[
                    SizedBox(width: 8),
                    _BadgePill(label: "Lowest Fare"),
                  ],
                ],
              ),
            ),

            // Details section
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Travel time row
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: Color(0xFF1A73E8),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Travel Time: ",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        formatSecondsToHHMMSS(travelTime),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A73E8),
                        ),
                      ),
                      if (isDelayed) ...[
                        SizedBox(width: 25),
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

                  if (badges.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.center,
                        child: Wrap(
                          spacing: 9,
                          runSpacing: 6,
                          children: [
                            for (final badge in badges)
                              _BadgePill(label: badge),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: 8),

                  // Route visualizer
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: SizedBox(
                      height: 26,
                      width: double.infinity,
                      child: navPainter(pathJSON, route_id),
                    ),
                  ),

                  SizedBox(height: 6),

                  // Time row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTimeChip(
                        time: DateFormat('hh:mm a').format(DateTime.now()),
                        label: "Depart",
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                      _buildTimeChip(
                        time: DateFormat('hh:mm a').format(
                          DateTime.now().add(
                            Duration(seconds: travelTime.toInt()),
                          ),
                        ),
                        label: "Arrive",
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  // Divider
                  Divider(height: 1, color: Colors.grey.withValues(alpha: 0.3)),

                  SizedBox(height: 10),

                  // Fare information
                  _buildFareRow(
                    label: "Regular Fare",
                    amount: fareRates.$1,
                    isDiscounted: false,
                  ),
                  SizedBox(height: 6),
                  _buildFareRow(
                    label: "Discounted Fare",
                    amount: fareRates.$2,
                    isDiscounted: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Color(0xFF1A73E8)),
        SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
            color: isHighlighted ? Color(0xFF1A73E8) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeChip({required String time, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            time,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A73E8),
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
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          "₱${amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDiscounted ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// Small colored label shown on a route card that highlights a route's
/// advantage (fastest, least walking, least transfers).
class _BadgePill extends StatelessWidget {
  final String label;

  const _BadgePill({required this.label});

  static const Map<String, Color> _badgeColors = {
    "Fastest Route": Color(0xFF0D904F),
    "Least Walking": Color(0xFF1A73E8),
    "Least Transfers": Color(0xFFE37400),
    "Lowest Fare": Color.fromARGB(255, 98, 247, 165),
  };

  static const Map<String, IconData> _badgeIcons = {
    "Fastest Route": Icons.bolt,
    "Least Walking": Icons.directions_walk,
    "Least Transfers": Icons.swap_horiz,
    "Lowest Fare": Icons.payments_outlined,
  };

  @override
  Widget build(BuildContext context) {
    Color badgeColor = _badgeColors[label] ?? Colors.grey;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_badgeIcons[label] ?? Icons.star, color: badgeColor, size: 12),
          SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
