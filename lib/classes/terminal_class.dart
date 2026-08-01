class Terminal {
  int id;
  String name;
  double longitude;
  double latitude;
  String type = 'misc';
  String? barangay;

  Terminal({
    required this.id,
    required this.name,
    required this.longitude,
    required this.latitude,
    this.type = 'misc',
    this.barangay,
  });
}