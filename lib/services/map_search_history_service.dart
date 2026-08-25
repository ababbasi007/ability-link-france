import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

import '../models/map_search_history.dart';
import 'user_activity_service.dart';

/// Persists recent map searches under `users/{uid}.mapPrefs.recentSearches`.
///
/// Signed-out users keep history for the current session only.
class MapSearchHistoryService {
  MapSearchHistoryService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  final List<String> _session = [];
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSub;
  final _controller = StreamController<List<String>>.broadcast();

  static const _localFileName = 'cached_map_searches.json';

  Future<File> _localFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_localFileName');
  }

  Future<void> _saveLocal(List<String> items) async {
    try {
      final f = await _localFile();
      await f.writeAsString(jsonEncode(items));
    } catch (_) {}
  }

  Future<List<String>> _loadLocal() async {
    try {
      final f = await _localFile();
      if (!f.existsSync()) return const [];
      final raw = await f.readAsString();
      final list = jsonDecode(raw);
      if (list is List) return list.whereType<String>().toList();
    } catch (_) {}
    return const [];
  }

  Stream<List<String>> watchRecent() {
    if (_authSub == null) {
      _startWatching();
      // Seed session from local file immediately so offline mode shows history.
      _loadLocal().then((cached) {
        if (_session.isEmpty && cached.isNotEmpty) {
          _session
            ..clear()
            ..addAll(cached);
          _emit();
        }
      });
    }
    _controller.add(List.unmodifiable(_session));
    return _controller.stream;
  }

  void _startWatching() {
    _authSub = _auth.authStateChanges().listen(_onAuth);
  }

  void _onAuth(User? user) {
    _docSub?.cancel();
    _docSub = null;
    if (user == null) {
      _emit();
      return;
    }
    _docSub = _userDoc(user.uid).snapshots().listen((snap) {
      final remote = parseRecentMapSearches(snap.data()?['mapPrefs']);
      _session
        ..clear()
        ..addAll(remote);
      _emit();
    });
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_session));
    }
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<void> remember(String query) async {
    final updated = pushRecentMapSearch(_session, query);
    _session
      ..clear()
      ..addAll(updated);
    _emit();
    // Persist locally for offline use.
    unawaited(_saveLocal(updated));
    unawaited(UserActivityService().recordSearch(query: query));

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _userDoc(uid).set({
      'mapPrefs': {'recentSearches': updated},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clear() async {
    _session.clear();
    _emit();
    unawaited(_saveLocal(const []));

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _userDoc(uid).set({
      'mapPrefs': {'recentSearches': <String>[]},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void dispose() {
    _authSub?.cancel();
    _docSub?.cancel();
    _controller.close();
  }
}
