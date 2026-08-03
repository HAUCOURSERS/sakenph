// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';

/// Stand-in widget for when the app waits for backend response
class WaitingForBackendResponse extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // to prevent the easy-exit feature of the parent background widget
      },
      child: Container(
        color: Colors.transparent,
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height,
        child: Center(
          child: LoadingAnimationWidget.fourRotatingDots(
            color: Colors.grey,
            size: responsiveSizeHeight(150),
          ),
        ),
      ),
    );
  }
}
