class JeepneyRoute {
  final String id;
  final String name;
  final String color;
  final Map<String, dynamic> geojson;

  JeepneyRoute(
  {
    required this.id,
    required this.name,
    required this.color,
    required this.geojson,
  }
);

factory JeepneyRoute.fromJson(Map<String, dynamic> json) {
  return JeepneyRoute(
    id: json['id'] as String,
    name: json['name'] as String,
    color: json['color'] as String,
    geojson: Map<String, dynamic>.from(json['geojson']),
    );
  }
}

