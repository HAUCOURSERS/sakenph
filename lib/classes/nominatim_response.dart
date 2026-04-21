class NominatimPlace {
  final int placeId;
  final String osmType;
  final int osmId;
  final double lat;
  final double lon;
  final String name;
  final String displayName;
  final String className;
  final String type;
  final int placeRank;
  final double importance;
  final String addressType;
  final List<String> boundingBox; // [minLat, maxLat, minLon, maxLon]

  NominatimPlace({
    required this.placeId,
    required this.osmType,
    required this.osmId,
    required this.lat,
    required this.lon,
    required this.name,
    required this.displayName,
    required this.className,
    required this.type,
    required this.placeRank,
    required this.importance,
    required this.addressType,
    required this.boundingBox,
  });

  factory NominatimPlace.fromJson(Map<String, dynamic> json) {
    return NominatimPlace(
      placeId: json['place_id'],
      osmType: json['osm_type'],
      osmId: json['osm_id'],
      lat: double.parse(json['lat']), // note: comes as String
      lon: double.parse(json['lon']), // note: comes as String
      name: json['name'] ?? '',
      displayName: json['display_name'],
      className: json['class'],
      type: json['type'],
      placeRank: json['place_rank'],
      importance: (json['importance'] as num).toDouble(),
      addressType: json['addresstype'],
      boundingBox: List<String>.from(json['boundingbox']),
    );
  }
}
