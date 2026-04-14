import 'package:sakenph/classes/RouteSegment.dart';


class RouteResponse {
  final List<RouteSegment> route;

  RouteResponse({required this.route});

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    return RouteResponse(
      route: (json['route'] as List)
          .map((segment) => RouteSegment.fromJson(segment))
          .toList(),
    );
  }
}