class RouteSegment {
  final String type;
  final List<List<double>> geometry;

  RouteSegment({required this.type, required this.geometry});

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    final coords = json['geometry'] as List;
    return RouteSegment(
      type: json['type'],
      geometry: (json['geometry'] as List)
          .map((coords) => List<double>.from(coords))
          .toList(),
    );
  }
}