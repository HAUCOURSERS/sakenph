import 'package:flutter/material.dart';

/// Flutter's print method can't print very long strings, so this method is used to print long strings in chunks of 800 characters.
void printLongString(String text) {
  final pattern = RegExp('.{1,800}'); // 800 chars per chunk
  pattern.allMatches(text).forEach((match) => print(match.group(0)));
}

/// Converts time in seconds into formatted time. Ex: 1h 30m 15s
String formatSecondsToHHMMSS(double totalSeconds) {
  Duration duration = Duration(seconds: totalSeconds.toInt());

  // Extract hours, minutes, and remaining seconds
  int hours = duration.inHours;
  int minutes = (duration.inMinutes % 60);
  int seconds = (duration.inSeconds % 60);

  String stringBuilder =
      "${hours > 0 ? ("${hours}h ") : ""}${minutes > 0 ? ("${minutes}m ") : ""}${seconds > 0 ? ("${seconds}s") : ""}";
  return stringBuilder;
}

Color hexToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex'; // add full opacity if no alpha given
  return Color(int.parse(hex, radix: 16));
}

/// Backend Response formats jeepney names where there are no whitespaces, which looks
/// terrible if to be displayed as it is in the route details
String formatLabelForJeepneyName(String value) {
  // Replace all hyphens with whitespace
  String result = value.replaceAll('-', ' ');

  // Insert a space before any uppercase letter that's preceded by a lowercase letter
  result = result.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );

  return result;
}
