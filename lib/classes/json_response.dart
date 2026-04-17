class ModeDetails {
  final String name;
  final String color;

  ModeDetails({required this.name, required this.color});

  factory ModeDetails.fromJson(Map<String, dynamic> json) {
    return ModeDetails(
      name: json['name'],
      color: json['color'],
    );
  }
}

class Mode {
  final String type;
  final ModeDetails details;

  Mode({required this.type, required this.details});

  factory Mode.fromJson(Map<String, dynamic> json) {
    return Mode(
      type: json['type'],
      details: ModeDetails.fromJson(json['details']),
    );
  }
}

class RouteSegment {
  final Mode mode;
  final List<List<double>> geometry;

  RouteSegment({required this.mode, required this.geometry});

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      mode: Mode.fromJson(json['mode']),
      geometry: (json['geometry'] as List)
          .map((coords) => List<double>.from(coords))
          .toList(),
    );
  }
}

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