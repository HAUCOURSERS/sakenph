import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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

/// Returns true if permissions are allowed
Future<bool> getGeolocatorPermission() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print('Location permissions are denied');
    } else {
      return true;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    print('Location permissions are permanently denied.');
  }

  return true;
}

/// To provide color outline to jeepney routes
String darkenHex(String hex, [double amount = 0.7]) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 3) {
    hex = hex.split('').map((c) => c * 2).join('');
  }

  int r = int.parse(hex.substring(0, 2), radix: 16);
  int g = int.parse(hex.substring(2, 4), radix: 16);
  int b = int.parse(hex.substring(4, 6), radix: 16);

  r = (r * (1 - amount)).round().clamp(0, 255);
  g = (g * (1 - amount)).round().clamp(0, 255);
  b = (b * (1 - amount)).round().clamp(0, 255);

  return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
}

/// Obtained from: https://stackoverflow.com/questions/59435322/measure-distance-between-two-locations
/// Calculates the distance between two points in latitude and longitude taking into account
/// the curvature of the earth. Returns the distance in kilometers.
double getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
  var R = 6371; // Radius of the earth in km
  var dLat = _deg2rad(lat2 - lat1); // deg2rad below
  var dLon = _deg2rad(lon2 - lon1);
  var a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(_deg2rad(lat1)) *
          Math.cos(_deg2rad(lat2)) *
          Math.sin(dLon / 2) *
          Math.sin(dLon / 2);
  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  var d = R * c; // Distance in km
  return d;
}

/// Converts degrees to radians
double _deg2rad(deg) {
  return deg * (Math.pi / 180);
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
