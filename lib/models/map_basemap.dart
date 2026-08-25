import 'package:flutter/material.dart';

/// Basemap options for the accessibility map (standard / satellite / terrain).
enum MapBasemapKind { standard, satellite, terrain }

class MapBasemap {
  const MapBasemap({
    required this.kind,
    required this.label,
    required this.icon,
    required this.urlTemplate,
    this.subdomains = const [],
    this.maxZoom = 19,
    this.attribution = '',
  });

  final MapBasemapKind kind;
  final String label;
  final IconData icon;
  final String urlTemplate;
  final List<String> subdomains;
  final double maxZoom;
  final String attribution;

  static const all = <MapBasemap>[
    MapBasemap(
      kind: MapBasemapKind.standard,
      label: 'Standard',
      icon: Icons.map_outlined,
      urlTemplate: 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
      maxZoom: 20,
      attribution: '© OpenStreetMap © CARTO',
    ),
    MapBasemap(
      kind: MapBasemapKind.satellite,
      label: 'Satellite',
      icon: Icons.satellite_alt_outlined,
      // ArcGIS World Imagery uses z/y/x tile order.
      urlTemplate:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      maxZoom: 19,
      attribution: '© Esri',
    ),
    MapBasemap(
      kind: MapBasemapKind.terrain,
      label: 'Terrain',
      icon: Icons.terrain_outlined,
      urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c'],
      maxZoom: 17,
      attribution: '© OpenStreetMap © OpenTopoMap',
    ),
  ];

  static MapBasemap byKind(MapBasemapKind kind) =>
      all.firstWhere((b) => b.kind == kind, orElse: () => all.first);

  static MapBasemap byIndex(int index) {
    if (index < 0 || index >= all.length) return all.first;
    return all[index];
  }

  static int indexOf(MapBasemapKind kind) {
    final i = all.indexWhere((b) => b.kind == kind);
    return i < 0 ? 0 : i;
  }

  static MapBasemapKind? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final k in MapBasemapKind.values) {
      if (k.name == raw) return k;
    }
    return null;
  }
}
