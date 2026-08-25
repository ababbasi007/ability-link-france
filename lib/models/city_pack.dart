import 'dart:math' as math;

/// A named bounding box + zoom range used for offline tile downloads.
class CityPack {
  const CityPack({
    required this.id,
    required this.name,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    this.minZoom = 12,
    this.maxZoom = 15,
    this.emoji = '🗺️',
  });

  final String id;
  final String name;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
  final int minZoom;
  final int maxZoom;
  final String emoji;

  /// Approximate tile count across all zoom levels in the bounding box.
  int estimateTileCount() {
    var count = 0;
    for (var z = minZoom; z <= maxZoom; z++) {
      final xMin = _lngToTileX(minLng, z);
      final xMax = _lngToTileX(maxLng, z);
      final yMin = _latToTileY(maxLat, z); // y axis is flipped
      final yMax = _latToTileY(minLat, z);
      count += (xMax - xMin + 1) * (yMax - yMin + 1);
    }
    return count;
  }

  String get estimateSizeMb {
    final tiles = estimateTileCount();
    // Average compressed OSM tile ≈ 15 KB.
    final mb = (tiles * 15) / 1024;
    if (mb < 1) return '< 1 MB';
    return '~${mb.round()} MB';
  }

  static int _lngToTileX(double lng, int z) =>
      ((lng + 180) / 360 * (1 << z)).floor();

  static int _latToTileY(double lat, int z) {
    final latRad = lat * math.pi / 180;
    final n = 1 << z;
    return ((1 -
                (math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi)) /
            2 *
            n)
        .floor();
  }
}

/// Preset city packs shipped with the app.
const cityPacks = <CityPack>[
  CityPack(
    id: 'paris-center',
    name: 'Paris – Centre',
    emoji: '🗼',
    minLat: 48.815,
    maxLat: 48.905,
    minLng: 2.265,
    maxLng: 2.420,
    minZoom: 12,
    maxZoom: 15,
  ),
  CityPack(
    id: 'nyc-midtown',
    name: 'New York – Midtown',
    emoji: '🗽',
    minLat: 40.735,
    maxLat: 40.780,
    minLng: -74.005,
    maxLng: -73.940,
    minZoom: 12,
    maxZoom: 15,
  ),
  CityPack(
    id: 'london-center',
    name: 'London – Centre',
    emoji: '🎡',
    minLat: 51.480,
    maxLat: 51.540,
    minLng: -0.175,
    maxLng: 0.010,
    minZoom: 12,
    maxZoom: 15,
  ),
  CityPack(
    id: 'berlin-mitte',
    name: 'Berlin – Mitte',
    emoji: '🐻',
    minLat: 52.480,
    maxLat: 52.555,
    minLng: 13.340,
    maxLng: 13.440,
    minZoom: 12,
    maxZoom: 15,
  ),
];
