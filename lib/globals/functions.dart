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
