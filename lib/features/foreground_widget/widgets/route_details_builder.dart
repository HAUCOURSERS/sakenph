import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/foreground_widget/functions.dart';
import 'package:sakenph/globals/functions/computations.dart';
import 'package:sakenph/globals/functions/formattings.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';

/// Used by _PreviewWindowForSuggestedPath. Builds the Row() widgets to form
/// the display
class RouteDetailsBuilder extends StatelessWidget {
  const RouteDetailsBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    // force update during res change
    MediaQuery.sizeOf(context);
    // Cap the visible list height — beyond this it scrolls.
    double maxListHeight = responsiveSizeHeight(220.0);
    // Roughly how tall one row is, used to decide whether scrolling/fade is even needed.
    double approxRowHeight = responsiveSizeHeight(52.0);

    MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();
    List<(String, String, double, String, int, int)> routeDetails = buildTravelDetails(
      mapHelperProvider.getSuggestedShortestPaths,
      mapHelperProvider.getSelectedRouteId,
    );

    final bool needsScroll =
        (routeDetails.length * approxRowHeight) > maxListHeight / 2;

    Widget routeList = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, (name, hexcolor, value, fare, travelTime, delay))
            in routeDetails.indexed) ...[
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                // Icon
                _buildModeIcon(name, hexcolor),
                SizedBox(width: 10),
                // Name + Fare + Travel Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (fare.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          fare,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Color(0xFF0D9488),
                          ),
                          SizedBox(width: 4),
                          Text(
                            formatSecondsToWords(travelTime.toDouble()),
                            style: TextStyle(
                              fontSize: 12,
                            color: Color(0xFF0D9488),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (delay > 60) ...[
                            SizedBox(width: 6),
                            Text(
                              "+${(delay / 60).floor()} min delay",
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Distance
                Text(
                  formatDistance(value),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (i < routeDetails.length - 1)
            Divider(
              height: 1,
              color: Colors.grey.withValues(alpha: 0.15),
            ),
        ],
      ],
    );

    if (needsScroll) {
      routeList = ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.black, Colors.transparent],
            stops: [0.0, 0.85, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: responsiveSizeHeight(25)),
            child: routeList,
          ),
        ),
      );
      routeList = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxListHeight),
        child: routeList,
      );
    }

    return routeList;
  }

  Widget _buildModeIcon(String name, String hexcolor) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: hexToColor(hexcolor).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: (name == "Walk")
            ? Icon(
                Icons.directions_walk,
                color: hexToColor(hexcolor),
                size: 20,
              )
            : (name == "Tricycle")
            ? ImageIcon(
                AssetImage('assets/img/tricycle-icon.png'),
                size: 20,
                color: hexToColor(hexcolor),
              )
            : ImageIcon(
                AssetImage('assets/img/jeepney-icon.png'),
                size: 20,
                color: hexToColor(hexcolor),
              ),
      ),
    );
  }
}
