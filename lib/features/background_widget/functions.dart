import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

Future<Position> getUserCurrentLoc() async {
  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
  return position;
}
