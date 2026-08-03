// ignore_for_file: non_constant_identifier_names

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/background_widget/functions.dart';
import 'package:sakenph/features/foreground_widget/functions.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/formattings.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// Widget where route details are already processed.
///
/// The one with the colored lines indicating your walk/jeep/tricycle modes
class SuggestedPathWidgetTemplate extends StatelessWidget {
  /// Index number in the iteration when the widgets are being built
  final int choice_idx;

  /// Distinct colors for each path header (different from badge colors)
  static const List<Color> _pathColors = [
    Color(0xFF6750A4), // Path #1 - Purple
    Color(0xFF0D9488), // Path #2 - Teal
    Color(0xFFC2410C), // Path #3 - Deep Orange
    Color(0xFF7C3AED), // Path #4 - Violet
    Color(0xFF0369A1), // Path #5 - Sky Blue
  ];

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
    Set<String> badges = computeRouteBadges(
      mapHelperProvider.getSuggestedShortestPaths,
      route_id,
    );
    (int, int) routeDurations = computeRouteDelay(pathJSON, route_id);
    int delaySeconds = routeDurations.$2 - routeDurations.$1;
    bool isDelayed = delaySeconds > 60;

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
            // Header with path number and badges
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: _pathColors[choice_idx % _pathColors.length],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.route,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Path #${choice_idx + 1}",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (badges.isNotEmpty || isDelayed) ...[
                    Spacer(),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (isDelayed)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber,
                                  color: Color(0xFFDC2626),
                                  size: 13,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  "+${(delaySeconds / 60).floor()} min delay",
                                  style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        for (final badge in badges)
                          _BadgePill(label: badge, isOnHeader: true),
                      ],
                    ),
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
                  _buildInfoRow(
                    icon: Icons.access_time,
                    label: "Travel Time",
                    value: formatSecondsToHHMMSS(travelTime),
                    isHighlighted: true,
                  ),

                  SizedBox(height: 12),

                  // Route visualizer
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: SizedBox(
                      height: 24,
                      width: double.infinity,
                      child: navPainter(pathJSON, route_id),
                    ),
                  ),

                  SizedBox(height: 8),

                  // Time row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTimeChip(
                        time: DateFormat('hh:mm a').format(DateTime.now()),
                        label: "Depart",
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
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

                  SizedBox(height: 12),

                  // Divider
                  Divider(
                    height: 1,
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),

                  SizedBox(height: 12),

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
        Icon(
          icon,
          size: 18,
          color: Color(0xFF1A73E8),
        ),
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
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
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
  final bool isOnHeader;

  const _BadgePill({required this.label, this.isOnHeader = false});

  static const Map<String, Color> _badgeColors = {
    "Fastest Route": Color(0xFF0D904F),
    "Least Walking": Color(0xFF1A73E8),
    "Least Transfers": Color(0xFFE37400),
  };

  static const Map<String, IconData> _badgeIcons = {
    "Fastest Route": Icons.bolt,
    "Least Walking": Icons.directions_walk,
    "Least Transfers": Icons.swap_horiz,
  };

  @override
  Widget build(BuildContext context) {
    Color badgeColor = _badgeColors[label] ?? Colors.grey;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isOnHeader ? Colors.white : badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _badgeIcons[label] ?? Icons.star,
            color: isOnHeader ? badgeColor : Colors.white,
            size: 13,
          ),
          SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: isOnHeader ? badgeColor : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
