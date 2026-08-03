/*
This file contains helper functions that aims to compute the optimal sizes for your widgets
depending on the user's device resolution
*/

// Context:
// These numbers are from my phone's MediaQuery.sizeOf() numbers. During development,
// I kept using static numbers, causing it to look terrible once my other groupmates
// compiled the app and used the features.
//
// I like how these static number sizes looked when they were rendered the widgets in my phone so I will
// use these numbers as references for my adjustment formulas
//
// - Josef Miko
import 'dart:math';

import 'package:flutter/material.dart';

// These values will serve as reference values to decide the multiplier of the functions, meaning
// your provided value will expand/shrink depending on how far the client's device resolution is to
// these values.
double get _getReferenceWidth => 462.03206671109666;
double get _getReferenceHeight => 1010.9090496651124;

/// Returns the proper user width resolution
double get getResolutionWidth {
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final physicalSize = view.physicalSize;
  final devicePixelRatio = view.devicePixelRatio;

  return physicalSize.width / devicePixelRatio;
}

/// Returns the proper user height resolution
double get getResolutionHeight {
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final physicalSize = view.physicalSize;
  final devicePixelRatio = view.devicePixelRatio;

  return physicalSize.height / devicePixelRatio;
}

/// Mainly for widget properties to adjust their sizes based on user device's width.
/// Best utilized on horizontal properties. If you want to set minimum value, provide it at the 2nd argument
double responsiveSizeWidth(
  double estimateSize, [
  double maxSize = double.infinity,
]) {
  double responsiveSize =
      estimateSize * (getResolutionWidth / _getReferenceWidth);
  return min(responsiveSize, maxSize);
}

/// Mainly for widget properties to adjust their sizes based on user device's height.
/// Best utilized on vertical properties. If you want to set minimum value, provide it at the 2nd argument
double responsiveSizeHeight(
  double estimateSize, [
  double maxSize = double.infinity,
]) {
  double responsiveSize =
      estimateSize * (getResolutionHeight / _getReferenceHeight);
  return min(responsiveSize, maxSize);
}
