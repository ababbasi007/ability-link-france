import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/city_pack.dart';

/// Progress snapshot for a running download.
class TileDownloadProgress {
  const TileDownloadProgress({
    required this.packId,
    required this.done,
    required this.total,
    this.failed = 0,
    this.finished = false,
    this.error,
  });

  final String packId;
  final int done;
  final int total;
  final int failed;
  final bool finished;
  final String? error;

  double get fraction => total == 0 ? 0.0 : done / total;
}

/// Downloads and manages offline map tiles stored under the app cache directory.
///
/// Tiles are stored at:
///   `<cacheDir>/map_tiles/<packId>/<z>/<x>/<y>.png`
class TileCacheService {
  TileCacheService._();
  static final TileCacheService instance = TileCacheService._();

  // URL template used for downloads (Standard CartoDB light layer).
  static const _urlTemplate =
      'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';

  final Map<String, StreamController<TileDownloadProgress>> _controllers = {};
  final Map<String, bool> _active = {};

  // ── directory helpers ──────────────────────────────────────────────────────

  Future<Directory> _packDir(String packId) async {
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/map_tiles/$packId');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  File _tileFile(Directory packDir, int z, int x, int y) =>
      File('${packDir.path}/$z/$x/$y.png');

  // ── public API ─────────────────────────────────────────────────────────────

  /// Returns the on-disk tile file for [z]/[x]/[y], or null if not cached.
  Future<File?> getCached(String packId, int z, int x, int y) async {
    final dir = await _packDir(packId);
    final f = _tileFile(dir, z, x, y);
    return f.existsSync() ? f : null;
  }

  /// Returns the on-disk tile file for [z]/[x]/[y] across *all* packs,
  /// useful when you don't track which pack the tile came from.
  Future<File?> getAnyCached(int z, int x, int y) async {
    final base = await getApplicationCacheDirectory();
    for (final pack in cityPacks) {
      final f = File('${base.path}/map_tiles/${pack.id}/$z/$x/$y.png');
      if (f.existsSync()) return f;
    }
    return null;
  }

  /// `true` if every tile for [pack] exists on disk.
  Future<bool> isDownloaded(CityPack pack) async {
    final dir = await _packDir(pack.id);
    for (final (z, x, y) in _tiles(pack)) {
      if (!_tileFile(dir, z, x, y).existsSync()) return false;
    }
    return true;
  }

  /// Size on disk for [packId] in MB.
  Future<double> sizeOnDiskMb(String packId) async {
    final dir = await _packDir(packId);
    if (!dir.existsSync()) return 0;
    var bytes = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) bytes += await entity.length();
    }
    return bytes / (1024 * 1024);
  }

  /// Stream of download progress for [pack].
  /// Cancel the download by calling [cancelDownload].
  Stream<TileDownloadProgress> download(CityPack pack) {
    final packId = pack.id;
    _controllers[packId]?.close();
    final ctrl = StreamController<TileDownloadProgress>.broadcast();
    _controllers[packId] = ctrl;
    _active[packId] = true;

    unawaited(_runDownload(pack, ctrl));
    return ctrl.stream;
  }

  void cancelDownload(String packId) {
    _active[packId] = false;
  }

  Future<void> deletePackDir(String packId) async {
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/map_tiles/$packId');
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  // ── internal ───────────────────────────────────────────────────────────────

  Iterable<(int z, int x, int y)> _tiles(CityPack pack) sync* {
    for (var z = pack.minZoom; z <= pack.maxZoom; z++) {
      final xMin = _lngToTileX(pack.minLng, z);
      final xMax = _lngToTileX(pack.maxLng, z);
      final yMin = _latToTileY(pack.maxLat, z);
      final yMax = _latToTileY(pack.minLat, z);
      for (var x = xMin; x <= xMax; x++) {
        for (var y = yMin; y <= yMax; y++) {
          yield (z, x, y);
        }
      }
    }
  }

  Future<void> _runDownload(
    CityPack pack,
    StreamController<TileDownloadProgress> ctrl,
  ) async {
    final packId = pack.id;
    final tiles = _tiles(pack).toList();
    final total = tiles.length;
    var done = 0;
    var failed = 0;

    final dir = await _packDir(packId);
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      for (final (z, x, y) in tiles) {
        if (!(_active[packId] ?? false)) break;

        final tileFile = _tileFile(dir, z, x, y);
        if (tileFile.existsSync()) {
          done++;
          if (ctrl.isClosed) break;
          ctrl.add(
            TileDownloadProgress(packId: packId, done: done, total: total),
          );
          continue;
        }

        tileFile.parent.createSync(recursive: true);

        final url = _urlTemplate
            .replaceAll('{z}', '$z')
            .replaceAll('{x}', '$x')
            .replaceAll('{y}', '$y');

        try {
          final req = await client.getUrl(Uri.parse(url));
          req.headers.set('User-Agent', 'AbilityLink/1.0 tile-cache');
          final resp = await req.close();
          if (resp.statusCode == 200) {
            final bytes = await consolidateHttpClientResponseBytes(resp);
            await tileFile.writeAsBytes(bytes);
            done++;
          } else {
            failed++;
          }
        } catch (_) {
          failed++;
        }

        if (ctrl.isClosed) break;
        ctrl.add(
          TileDownloadProgress(
            packId: packId,
            done: done,
            total: total,
            failed: failed,
          ),
        );

        // Small delay to avoid hammering the tile server.
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }
    } finally {
      client.close();
      _active[packId] = false;
      if (!ctrl.isClosed) {
        ctrl.add(
          TileDownloadProgress(
            packId: packId,
            done: done,
            total: total,
            failed: failed,
            finished: true,
          ),
        );
        await ctrl.close();
      }
    }
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
