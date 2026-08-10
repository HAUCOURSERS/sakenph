// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:sakenph/features/background_widget/widgets/suggested_route_widget_list_builder.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';

/// Widget that will display route choices given by backend
class DisplaySuggestedRoutes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // If you want to change the width of the route choice display widgets, modify this
    double choiceWidgetWidth = responsiveSizeWidth(420, 380);

    return SizedBox(
      child: Stack(
        children: [
          Positioned(
            top: responsiveSizeHeight(200),
            left:
                (MediaQuery.sizeOf(context).width / 2) -
                (choiceWidgetWidth / 2),

            child: Container(
              alignment: Alignment.topCenter,
              width: choiceWidgetWidth,
              height:
                  MediaQuery.sizeOf(context).height - responsiveSizeHeight(200),
              child: SuggestedRouteWidgetListBuilder(),
            ),
          ),
          Positioned(
            top: responsiveSizeHeight(135),
            left: responsiveSizeWidth(MediaQuery.sizeOf(context).width * 0.125),
            right: responsiveSizeWidth(
              MediaQuery.sizeOf(context).width * 0.125,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsiveSizeHeight(16),
                vertical: responsiveSizeHeight(14),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 18, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    "Tap a path card to view route",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: responsiveSizeHeight(14),
                      fontWeight: FontWeight.w500,
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
}
