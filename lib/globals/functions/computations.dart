import 'dart:math' as Math;

/// Obtained from: https://stackoverflow.com/questions/59435322/measure-distance-between-two-locations<br/>
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

/// Receives a string hex, darkens it by 70% and returns the darkened hex value that starts with "#"
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

/// Converts given meters into formatted meters or kilometers
String formatDistance(double value) {
  if (value >= 1000) {
    return "${(value / 1000).toStringAsFixed(2)}km";
  } else {
    return "${(value).toStringAsFixed(2)}m";
  }
}
