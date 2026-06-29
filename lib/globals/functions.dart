import 'package:geolocator/geolocator.dart';

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
String darkenHex(String hex, [double amount = 0.2]) {
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
