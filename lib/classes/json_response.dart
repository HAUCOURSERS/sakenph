class ModeFare {
  final double regular;
  final double discounted;

  ModeFare({required this.regular, required this.discounted});

  factory ModeFare.fromJson(Map<String, dynamic> json) {
    return ModeFare(
      regular: json['regular'],
      discounted: json['discounted']
    );
  }
}

class ModeDetails {
  final String name;
  final String color;
<<<<<<< HEAD
  final ModeFare modeFare;

  ModeDetails({required this.name, required this.color, required this.modeFare});
=======

  ModeDetails({required this.name, required this.color});
>>>>>>> f797c015f9272e8cb4aa91e729c20eb11162b00d

  factory ModeDetails.fromJson(Map<String, dynamic> json) {
    return ModeDetails(
      name: json['name'],
<<<<<<< HEAD
      modeFare: ModeFare.fromJson(json['fare']),
=======
>>>>>>> f797c015f9272e8cb4aa91e729c20eb11162b00d
      color: json['color'],
    );
  }
}

class Mode {
  final String type;
<<<<<<< HEAD
  final ModeDetails details;

  Mode({required this.type, required this.details});
=======
  final ModeFare modeFare;
  final ModeDetails details;

  Mode({required this.type, required this.modeFare, required this.details});
>>>>>>> f797c015f9272e8cb4aa91e729c20eb11162b00d

  factory Mode.fromJson(Map<String, dynamic> json) {
    return Mode(
      type: json['type'],
<<<<<<< HEAD
=======
      modeFare: ModeFare.fromJson(json['fare']),
>>>>>>> f797c015f9272e8cb4aa91e729c20eb11162b00d
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
  final Map<String, List<RouteSegment>> routes;

  RouteResponse({required this.routes});

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    final routesJson = json['routes'] as Map<String, dynamic>;
    return RouteResponse(
      routes: routesJson.map(
        (key, value) => MapEntry(
          key,
          (value as List)
              .map((segment) => RouteSegment.fromJson(segment))
              .toList(),
        ),
      ),
    );
  }
}