import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/place.dart';

/// Persists `AccessiblePlace` lists to local JSON files so they are available
/// without a network connection.
///
/// Two caches are maintained:
///  - **favorites** – the union of all places saved in any favorite list.
///  - **recent**   – the last [maxRecent] places opened in a detail sheet.
class LocalPlaceCache {
  LocalPlaceCache._();
  static final LocalPlaceCache instance = LocalPlaceCache._();

  static const int maxRecent = 10;
  static const _favoritesFile = 'cached_favorites.json';
  static const _recentFile = 'cached_recent_places.json';

  // ── file helpers ──────────────────────────────────────────────────────────

  Future<File> _file(String name) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$name');
  }

  Future<List<Map<String, dynamic>>> _read(String name) async {
    try {
      final f = await _file(name);
      if (!f.existsSync()) return const [];
      final raw = await f.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _write(String name, List<Map<String, dynamic>> maps) async {
    try {
      final f = await _file(name);
      await f.writeAsString(jsonEncode(maps));
    } catch (_) {
      // Best-effort: never crash the app if the write fails.
    }
  }

  // ── favorites ─────────────────────────────────────────────────────────────

  /// Overwrite the favorites cache with [places].
  Future<void> saveFavorites(List<AccessiblePlace> places) =>
      _write(_favoritesFile, places.map((p) => p.toJson()).toList());

  /// Read the favorites cache. Returns an empty list if nothing is stored yet.
  Future<List<AccessiblePlace>> loadFavorites() async {
    final maps = await _read(_favoritesFile);
    return maps
        .map((m) => AccessiblePlace.fromJson(m))
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  // ── recent places ─────────────────────────────────────────────────────────

  /// Push [place] to the front of the recent list, deduplicating by id.
  Future<void> pushRecent(AccessiblePlace place) async {
    final existing = await _read(_recentFile);
    final updated = [
      place.toJson(),
      ...existing.where((m) => m['_id'] != place.id),
    ];
    if (updated.length > maxRecent) updated.removeRange(maxRecent, updated.length);
    await _write(_recentFile, updated);
  }

  /// Read the recent places cache, newest first.
  Future<List<AccessiblePlace>> loadRecent() async {
    final maps = await _read(_recentFile);
    return maps
        .map((m) => AccessiblePlace.fromJson(m))
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  /// Clear all caches (e.g. on sign-out).
  Future<void> clearAll() async {
    await _write(_favoritesFile, const []);
    await _write(_recentFile, const []);
  }
}
