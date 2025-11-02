class Terminal {
  int id;
  String name;
  double longitude;
  double latitude;
  String type = 'misc';

  Terminal({
    required this.id,
    required this.name,
    required this.longitude,
    required this.latitude,
    type
  });
}