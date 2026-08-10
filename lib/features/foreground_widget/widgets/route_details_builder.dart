import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/foreground_widget/functions.dart';
import 'package:sakenph/globals/functions/computations.dart';
import 'package:sakenph/globals/functions/formattings.dart';
import 'package:sakenph/globals/functions/route_timing.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';

/// Used by _PreviewWindowForSuggestedPath. Builds the Row() widgets to form
/// the display
class RouteDetailsBuilder extends StatefulWidget {
  const RouteDetailsBuilder({super.key});

  @override
  State<RouteDetailsBuilder> createState() => _RouteDetailsBuilderState();
}

class _RouteDetailsBuilderState extends State<RouteDetailsBuilder> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxListHeight = kIsWeb
        ? math.min(320.0, screenHeight * 0.36)
        : responsiveSizeHeight(220.0);

    final mapHelperProvider = context.read<MapHelperProvider>();
    final routeDetails = buildTravelDetails(
      mapHelperProvider.getSuggestedShortestPaths,
      mapHelperProvider.getSelectedRouteId,
    );
    final displayRouteDetails =
        routeDetails.isNotEmpty &&
            routeDetails.last.$1 == zeroDistanceTransferLabel
        ? routeDetails.sublist(0, routeDetails.length - 1)
        : routeDetails;

    final routeList = ListView.separated(
      controller: _scrollController,
      primary: false,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(right: kIsWeb ? 8 : 4),
      itemCount: displayRouteDetails.length + 1,
      itemBuilder: (context, index) {
        if (index == displayRouteDetails.length) {
          return _buildDestinationTerminator();
        }

        final (
          name,
          hexcolor,
          value,
          fare,
          travelTime,
          delay,
          transferWait,
          modeType,
        ) = displayRouteDetails[index];
        final isZeroDistanceTransfer = name == zeroDistanceTransferLabel;
        return _buildRouteSegment(
          name: name,
          hexcolor: hexcolor,
          modeType: modeType,
          value: value,
          fare: fare,
          travelTime: travelTime,
          delay: delay,
          transferWait: transferWait,
          isZeroDistanceTransfer: isZeroDistanceTransfer,
        );
      },
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxListHeight),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: kIsWeb,
        trackVisibility: kIsWeb,
        interactive: true,
        thickness: kIsWeb ? 9 : 6,
        radius: Radius.circular(8),
        scrollbarOrientation: ScrollbarOrientation.right,
        child: routeList,
      ),
    );
  }

  Widget _buildDestinationTerminator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_on, color: Colors.green[700], size: 20),
          ),
          SizedBox(width: 10),
          Text(
            "Arrived at destination",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSegment({
    required String name,
    required String hexcolor,
    required String modeType,
    required double value,
    required String fare,
    required int travelTime,
    required int delay,
    required int transferWait,
    required bool isZeroDistanceTransfer,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          _buildModeIcon(name, hexcolor, modeType),
          SizedBox(width: 10),
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
                if (!isZeroDistanceTransfer) ...[
                  SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                        ],
                      ),
                      if (delay > 0)
                        Text(
                          "+${(delay / 60).floor()} min delay",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
                if (transferWait > 0)
                  Text(
                    "Estimated transfer wait: 0–5 minutes",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0D9488),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
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
    );
  }

  Widget _buildModeIcon(String name, String hexcolor, String modeType) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: hexToColor(hexcolor).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: (modeType == "walk")
            ? Icon(Icons.directions_walk, color: hexToColor(hexcolor), size: 23)
            : (modeType == "trike")
            ? ImageIcon(
                AssetImage('assets/img/tricycle-icon.png'),
                size: 26,
                color: hexToColor(hexcolor),
              )
            : ImageIcon(
                AssetImage('assets/img/jeepney-icon.png'),
                size: 26,
                color: hexToColor(hexcolor),
              ),
      ),
    );
  }
}
