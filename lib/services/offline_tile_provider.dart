import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

import '../models/map_basemap.dart';
import 'tile_cache_service.dart';

/// Reads city-pack tiles from disk when available, then falls back to network.
class OfflineFirstTileProvider extends NetworkTileProvider {
  OfflineFirstTileProvider({super.headers, this.cacheEnabled = true});

  final bool cacheEnabled;

  static bool supportsOfflineCache(MapBasemap basemap) =>
      basemap.kind == MapBasemapKind.standard;

  @override
  ImageProvider getImageWithCancelLoadingSupport(
    TileCoordinates coordinates,
    TileLayer options,
    Future<void> cancelLoading,
  ) {
    if (!cacheEnabled) {
      return super.getImageWithCancelLoadingSupport(
        coordinates,
        options,
        cancelLoading,
      );
    }

    final z = _effectiveZoom(coordinates, options);
    final x = coordinates.x.round();
    final y = _effectiveY(coordinates, options);

    return _OfflineTileImageProvider(
      z: z,
      x: x,
      y: y,
      url: getTileUrl(coordinates, options),
      fallbackUrl: getTileFallbackUrl(coordinates, options),
      headers: headers,
    );
  }

  int _effectiveZoom(TileCoordinates coordinates, TileLayer options) {
    return (options.zoomOffset +
            (options.zoomReverse
                ? options.maxZoom - coordinates.z.toDouble()
                : coordinates.z.toDouble()))
        .round();
  }

  int _effectiveY(TileCoordinates coordinates, TileLayer options) {
    final z = _effectiveZoom(coordinates, options);
    return options.tms
        ? ((1 << z) - 1) - coordinates.y.round()
        : coordinates.y.round();
  }
}

@immutable
class _OfflineTileImageProvider
    extends ImageProvider<_OfflineTileImageProvider> {
  const _OfflineTileImageProvider({
    required this.z,
    required this.x,
    required this.y,
    required this.url,
    required this.fallbackUrl,
    required this.headers,
  });

  final int z;
  final int x;
  final int y;
  final String url;
  final String? fallbackUrl;
  final Map<String, String> headers;

  @override
  Future<_OfflineTileImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _OfflineTileImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadCodec(key, decode),
      scale: 1,
    );
  }

  Future<ui.Codec> _loadCodec(
    _OfflineTileImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    try {
      final cached = await TileCacheService.instance.getAnyCached(
        key.z,
        key.x,
        key.y,
      );
      if (cached != null && cached.existsSync()) {
        final bytes = await cached.readAsBytes();
        if (bytes.isNotEmpty) {
          return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
        }
      }
    } catch (_) {
      // Fall through to network.
    }

    for (final tileUrl in [key.url, if (key.fallbackUrl != null) key.fallbackUrl!]) {
      try {
        final bytes = await _fetchBytes(tileUrl, key.headers);
        if (bytes != null && bytes.isNotEmpty) {
          return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
        }
      } catch (_) {
        // Try next URL.
      }
    }

    return decode(
      await ui.ImmutableBuffer.fromUint8List(TileProvider.transparentImage),
    );
  }

  Future<Uint8List?> _fetchBytes(String tileUrl, Map<String, String> hdrs) async {
    if (kIsWeb) return null;
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(Uri.parse(tileUrl));
      hdrs.forEach(req.headers.set);
      if (!hdrs.containsKey('User-Agent')) {
        req.headers.set('User-Agent', 'com.abilitylink.app');
      }
      final resp = await req.close().timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in resp) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } finally {
      client.close(force: true);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _OfflineTileImageProvider &&
      z == other.z &&
      x == other.x &&
      y == other.y &&
      url == other.url;

  @override
  int get hashCode => Object.hash(z, x, y, url);
}
