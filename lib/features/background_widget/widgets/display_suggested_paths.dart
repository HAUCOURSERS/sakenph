// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:sakenph/features/background_widget/widgets/suggested_path_widget_list_builder.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';

/// Widget that will display route choices given by backend
class DisplaySuggestedPaths extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // If you want to change the width of the route choice display widgets, modify this
    double choiceWidgetWidth = responsiveSizeWidth(400, 370);

    return SizedBox(
      child: Stack(
        children: [
          Positioned(
            top: responsiveSizeHeight(200),
            left:
                (MediaQuery.sizeOf(context).width / 2) -
                (choiceWidgetWidth / 2),

            child: Container(
              alignment: Alignment.center,
              width: choiceWidgetWidth,
              height: MediaQuery.sizeOf(context).height,
              child: SuggestedPathWidgetListBuilder(),
            ),
          ),
          Positioned(
            top: responsiveSizeHeight(120),
            left: responsiveSizeWidth(MediaQuery.sizeOf(context).width * 0.125),
            right: responsiveSizeWidth(
              MediaQuery.sizeOf(context).width * 0.125,
            ),
            child: Container(
              padding: EdgeInsets.all(responsiveSizeHeight(10)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: Colors.black,
                  width: responsiveSizeHeight(1),
                ),
                // black outline
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 3), // shadow goes downward
                  ),
                ],
              ),
              child: Text(
                "Tap to view path",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: responsiveSizeHeight(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
