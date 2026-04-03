class ShotPosition {
  final int shotNumber; // 1-indexed
  final double lat;
  final double lng;

  const ShotPosition({
    required this.shotNumber,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toMap() => {
        'n': shotNumber,
        'lat': lat,
        'lng': lng,
      };

  factory ShotPosition.fromMap(Map<String, dynamic> m) => ShotPosition(
        shotNumber: (m['n'] as num).toInt(),
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
      );
}
