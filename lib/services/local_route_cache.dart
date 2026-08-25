import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/place.dart';
import 'routing_service.dart';

/// A navigation route saved locally for offline replay.
class CachedNavigationRoute {
  const CachedNavigationRoute({
    required this.id,
    required this.destinationPlaceId,
    required this.destinationName,
    required this.destinationLat,
    required this.destinationLng,
    required this.route,
    required this.savedAt,
  });

  final String id;
  final String destinationPlaceId;
  final String destinationName;
  final double destinationLat;
  final double destinationLng;
  final WalkingRoute route;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'destinationPlaceId': destinationPlaceId,
    'destinationName': destinationName,
    'destinationLat': destinationLat,
    'destinationLng': destinationLng,
    'route': route.toJson(),
    'savedAt': savedAt.toIso8601String(),
  };

  factory CachedNavigationRoute.fromJson(Map<String, dynamic> json) {
    return CachedNavigationRoute(
      id: (json['id'] as String?) ?? '',
      destinationPlaceId: (json['destinationPlaceId'] as String?) ?? '',
      destinationName: (json['destinationName'] as String?) ?? 'Destination',
      destinationLat: ((json['destinationLat'] as num?) ?? 0).toDouble(),
      destinationLng: ((json['destinationLng'] as num?) ?? 0).toDouble(),
      route: WalkingRoute.fromJson(
        (json['route'] as Map<String, dynamic>?) ?? const {},
      ),
      savedAt: DateTime.tryParse((json['savedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Persists planned walking routes for offline navigation replay.
class LocalRouteCache {
  LocalRouteCache._();
  static final LocalRouteCache instance = LocalRouteCache._();

  static const int maxRoutes = 20;
  static const _fileName = 'cached_navigation_routes.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<CachedNavigationRoute>> loadAll() async {
    try {
      final f = await _file();
      if (!f.existsSync()) return const [];
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is! List) return const [];
      final rows = decoded
          .whereType<Map<String, dynamic>>()
          .map(CachedNavigationRoute.fromJson)
          .where((r) => r.route.points.length >= 2)
          .toList();
      rows.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return rows;
    } catch (_) {
      return const [];
    }
  }

  Future<CachedNavigationRoute?> findForDestination(String placeId) async {
    if (placeId.isEmpty) return null;
    final rows = await loadAll();
    for (final row in rows) {
      if (row.destinationPlaceId == placeId) return row;
    }
    return null;
  }

  Future<void> save({
    required AccessiblePlace destination,
    required WalkingRoute route,
  }) async {
    if (route.points.length < 2) return;
    try {
      final existing = await loadAll();
      final id = destination.id.isNotEmpty
          ? destination.id
          : '${destination.lat}_${destination.lng}';
      final entry = CachedNavigationRoute(
        id: id,
        destinationPlaceId: destination.id,
        destinationName: destination.name,
        destinationLat: destination.lat,
        destinationLng: destination.lng,
        route: route.copyWith(source: route.source == 'cached' ? 'cached' : route.source),
        savedAt: DateTime.now(),
      );
      final updated = [
        entry,
        ...existing.where((r) => r.id != entry.id),
      ];
      if (updated.length > maxRoutes) {
        updated.removeRange(maxRoutes, updated.length);
      }
      final f = await _file();
      await f.writeAsString(
        jsonEncode(updated.map((r) => r.toJson()).toList()),
      );
    } catch (_) {
      // Best effort.
    }
  }

  Future<void> delete(String id) async {
    final rows = await loadAll();
    final updated = rows.where((r) => r.id != id).toList();
    final f = await _file();
    await f.writeAsString(
      jsonEncode(updated.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> clearAll() async {
    final f = await _file();
    if (f.existsSync()) {
      await f.writeAsString('[]');
    }
  }
}
