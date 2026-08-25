import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

/// Avoids hammering Firestore when client-side demo seeding is blocked by rules.
///
/// After the first `permission-denied`, further seed attempts for that catalog
/// are skipped (persisted locally so hot restart does not retry writes).
abstract final class SeedWriteGuard {
  static final Set<String> _blocked = {};
  static final Map<String, Future<int>> _inFlight = {};
  static Future<void>? _loadFuture;

  static const _fileName = 'seed_write_blocked.json';

  static Future<void> _ensureLoaded() {
    return _loadFuture ??= () async {
      try {
        final dir = await getApplicationSupportDirectory();
        final file = File('${dir.path}/$_fileName');
        if (!file.existsSync()) return;
        final raw = jsonDecode(await file.readAsString());
        if (raw is List) {
          _blocked.addAll(raw.whereType<String>());
        }
      } catch (_) {
        // Best-effort — in-memory guard still applies this session.
      }
    }();
  }

  static Future<bool> canWrite(String catalog) async {
    await _ensureLoaded();
    return !_blocked.contains(catalog);
  }

  static Future<void> block(String catalog) async {
    await _ensureLoaded();
    if (!_blocked.add(catalog)) return;
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/$_fileName');
      await file.writeAsString(jsonEncode(_blocked.toList()));
    } catch (_) {}
  }

  static bool isPermissionDenied(Object error) =>
      error is FirebaseException && error.code == 'permission-denied';

  static bool hasAuth(FirebaseAuth auth) => auth.currentUser != null;

  /// Runs [seed] at most once per catalog per process; concurrent callers share
  /// the same future so Firestore is not hit in parallel.
  static Future<int> runOnce(
    String catalog,
    FirebaseAuth auth,
    Future<int> Function() seed,
  ) async {
    await _ensureLoaded();
    if (_blocked.contains(catalog) || auth.currentUser == null) return 0;

    return _inFlight.putIfAbsent(catalog, () {
      return seed().whenComplete(() => _inFlight.remove(catalog));
    });
  }
}
