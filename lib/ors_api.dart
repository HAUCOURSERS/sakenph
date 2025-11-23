class OpenRouteService {
  String apiKey = 'apiKey';
  Uri getRoute(String pointA, String pointB) {
  
    return Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=$pointA&end=$pointB');
  }
}