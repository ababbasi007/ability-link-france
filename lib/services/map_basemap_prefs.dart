import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/map_basemap.dart';

/// Persists the last-selected map basemap locally.
class MapBasemapPrefs {
  MapBasemapPrefs._();
  static final MapBasemapPrefs instance = MapBasemapPrefs._();

  static const _fileName = 'map_basemap_kind.txt';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<MapBasemapKind> load({
    MapBasemapKind fallback = MapBasemapKind.standard,
  }) async {
    try {
      final f = await _file();
      if (!f.existsSync()) return fallback;
      final kind = MapBasemap.tryParse((await f.readAsString()).trim());
      return kind ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> save(MapBasemapKind kind) async {
    try {
      final f = await _file();
      await f.writeAsString(kind.name);
    } catch (_) {}
  }
}
