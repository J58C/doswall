class GeotagResponse {
  final bool success;
  final String? message;
  final List<String>? locationLists;
  final double? lat;
  final double? long;

  GeotagResponse({
    required this.success,
    this.message,
    this.locationLists,
    this.lat,
    this.long,
  });
}