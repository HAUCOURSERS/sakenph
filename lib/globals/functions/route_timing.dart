import 'dart:math' as math;

import 'package:sakenph/globals/functions/computations.dart';

const String zeroDistanceTransferLabel = "Transfer to next ride";
const int defaultTransferWaitSeconds = 5 * 60;

/// Timing for one route segment. All displayed route times should come from
/// this model so the segment values and route total cannot diverge.
class RouteSegmentTiming {
  final double distanceInKm;
  final int expectedSeconds;
  final int actualSeconds;
  final int transferWaitSeconds;

  const RouteSegmentTiming({
    required this.distanceInKm,
    required this.expectedSeconds,
    required this.actualSeconds,
    this.transferWaitSeconds = 0,
  });

  int get delaySeconds => math.max(0, actualSeconds - expectedSeconds);
  int get totalExpectedSeconds => expectedSeconds + transferWaitSeconds;
  int get totalActualSeconds => actualSeconds + transferWaitSeconds;
}

/// Aggregated timing for every segment in a route.
class RouteTiming {
  final List<RouteSegmentTiming> segments;

  const RouteTiming(this.segments);

  int get expectedSeconds => segments.fold(
    0,
    (total, segment) => total + segment.totalExpectedSeconds,
  );

  int get actualSeconds =>
      segments.fold(0, (total, segment) => total + segment.totalActualSeconds);

  int get delaySeconds =>
      segments.fold(0, (total, segment) => total + segment.delaySeconds);
}

/// Computes all route timing from one source of truth.
///
/// Traffic is applied per segment. If one segment has no valid traffic data,
/// only that segment falls back to its mode-based estimate.
RouteTiming computeRouteTiming(Map<String, dynamic> routeData, String routeId) {
  final routes = routeData["routes"];
  final entries = routes is Map<String, dynamic> ? routes[routeId] : null;
  if (entries is! List) return const RouteTiming([]);

  final timings = [
    for (final entry in entries)
      _computeSegmentTiming(entry as Map<String, dynamic>),
  ];
  final transferWaits = List<int>.filled(timings.length, 0);

  for (int currentIndex = 1; currentIndex < entries.length; currentIndex++) {
    final currentEntry = entries[currentIndex] as Map<String, dynamic>;
    if (!_isTransitEntry(currentEntry)) continue;

    int previousIndex = currentIndex - 1;
    while (previousIndex >= 0 &&
        _isWalkEntry(entries[previousIndex] as Map<String, dynamic>)) {
      previousIndex--;
    }
    if (previousIndex < 0) continue;

    final previousEntry = entries[previousIndex] as Map<String, dynamic>;
    if (!_isTransitEntry(previousEntry) ||
        !_isDifferentTransitRide(previousEntry, currentEntry)) {
      continue;
    }

    // Put the wait on the connector row when one exists; otherwise put it on
    // the next ride without changing that ride's displayed travel duration.
    final waitIndex = previousIndex + 1 < currentIndex
        ? previousIndex + 1
        : currentIndex;
    transferWaits[waitIndex] = defaultTransferWaitSeconds;
  }

  return RouteTiming([
    for (int index = 0; index < timings.length; index++)
      RouteSegmentTiming(
        distanceInKm: timings[index].distanceInKm,
        expectedSeconds: timings[index].expectedSeconds,
        actualSeconds: timings[index].actualSeconds,
        transferWaitSeconds: transferWaits[index],
      ),
  ]);
}

bool _isTransitEntry(Map<String, dynamic> entry) {
  final modeType = entry["mode"]?["type"]?.toString();
  return modeType == "jeep" || modeType == "trike";
}

bool _isWalkEntry(Map<String, dynamic> entry) =>
    entry["mode"]?["type"]?.toString() == "walk";

bool _isDifferentTransitRide(
  Map<String, dynamic> previousEntry,
  Map<String, dynamic> currentEntry,
) {
  final previousName = previousEntry["mode"]?["details"]?["name"]?.toString();
  final currentName = currentEntry["mode"]?["details"]?["name"]?.toString();
  if (previousName == null || currentName == null) return false;
  return previousName != currentName;
}

RouteSegmentTiming _computeSegmentTiming(Map<String, dynamic> entry) {
  final distanceInKm = _computeGeometryDistanceInKm(entry["geometry"]);
  final mode = entry["mode"];
  final estimatedSeconds = _estimateSeconds(
    distanceInKm,
    mode is Map ? mode["type"]?.toString() : null,
  );

  final traffic = entry["traffic"];
  final expectedDuration = traffic is Map ? traffic["expectedDuration"] : null;
  final actualDuration = traffic is Map ? traffic["actualDuration"] : null;
  final hasValidTraffic = expectedDuration is num && actualDuration is num;

  final expectedSeconds = hasValidTraffic
      ? _nonNegativeSeconds(expectedDuration)
      : estimatedSeconds;
  final actualSeconds = hasValidTraffic
      ? _nonNegativeSeconds(actualDuration)
      : estimatedSeconds;

  return RouteSegmentTiming(
    distanceInKm: distanceInKm,
    expectedSeconds: expectedSeconds,
    actualSeconds: actualSeconds,
  );
}

double _computeGeometryDistanceInKm(dynamic geometry) {
  if (geometry is! List) return 0;

  double distanceInKm = 0;
  for (int i = 0; i < geometry.length - 1; i++) {
    final first = geometry[i];
    final second = geometry[i + 1];
    if (first is! List ||
        second is! List ||
        first.length < 2 ||
        second.length < 2 ||
        first[0] is! num ||
        first[1] is! num ||
        second[0] is! num ||
        second[1] is! num) {
      continue;
    }

    final firstLongitude = (first[0] as num).toDouble();
    final firstLatitude = (first[1] as num).toDouble();
    final secondLongitude = (second[0] as num).toDouble();
    final secondLatitude = (second[1] as num).toDouble();
    distanceInKm += getDistanceFromLatLonInKm(
      firstLatitude,
      firstLongitude,
      secondLatitude,
      secondLongitude,
    );
  }
  return distanceInKm;
}

int _estimateSeconds(double distanceInKm, String? modeType) {
  final speedKph = switch (modeType) {
    "walk" => 4.5,
    "jeep" => 14.0,
    "trike" => 23.0,
    _ => 0.0,
  };
  if (speedKph <= 0) return 0;
  return (distanceInKm / (speedKph / 3600)).round();
}

int _nonNegativeSeconds(num value) => math.max(0, value.toInt());
