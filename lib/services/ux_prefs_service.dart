import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/ux_prefs.dart';
import '../models/user_profile.dart';

class UxPrefsService {
  UxPrefsService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final id = uid;
    if (id == null) return null;
    return _db.collection('users').doc(id);
  }

  Future<void> ensureSeeded() async {
    final doc = _userDoc;
    if (doc == null) return;
    final snap = await doc.get();
    final data = snap.data();
    if (data == null) return;
    final prefs = data['preferences'];
    if (prefs is Map && prefs.isNotEmpty) return;
    final seeded = UxPrefs.fromMaps(
      const {},
      data['personal'] is Map
          ? Map<String, dynamic>.from(data['personal'] as Map)
          : const {},
    );
    await doc.set({
      'preferences': seeded.toPreferencesMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> save(UxPrefs prefs) async {
    final doc = _userDoc;
    if (doc == null) throw StateError('Sign in required');
    await doc.set({
      'preferences': prefs.toPreferencesMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await doc.update({'personal.preferredLanguage': prefs.language});
  }

  UxPrefs fromProfile(UserProfile? profile) => UxPrefs.fromProfile(profile);
}
