import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/accessible_routing_prefs.dart';

/// Persists [AccessibleRoutingPrefs] locally for the map routing engine.
class AccessibleRoutingPrefsStore {
  AccessibleRoutingPrefsStore._();
  static final AccessibleRoutingPrefsStore instance =
      AccessibleRoutingPrefsStore._();

  static const _fileName = 'accessible_routing_prefs.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<AccessibleRoutingPrefs> load({
    AccessibleRoutingPrefs fallback = AccessibleRoutingPrefs.defaults,
  }) async {
    try {
      final f = await _file();
      if (!f.existsSync()) return fallback;
      final raw = jsonDecode(await f.readAsString());
      if (raw is Map<String, dynamic>) {
        return AccessibleRoutingPrefs.fromMap(raw);
      }
      if (raw is Map) {
        return AccessibleRoutingPrefs.fromMap(
          Map<String, dynamic>.from(raw),
        );
      }
    } catch (_) {}
    return fallback;
  }

  Future<void> save(AccessibleRoutingPrefs prefs) async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(prefs.toMap()));
    } catch (_) {}
  }
}
