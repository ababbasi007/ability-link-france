import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/ai_safety.dart';
import '../models/place.dart';
import '../models/service_provider.dart';
import 'admin_service.dart';
import 'places_service.dart';
import 'providers_service.dart';

class TrustService {
  TrustService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    PlacesService? places,
    ProvidersService? providers,
    AdminService? admin,
  }) : _db = db ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _places = places ?? PlacesService(),
       _providers = providers ?? ProvidersService(),
       _admin = admin ?? AdminService();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final PlacesService _places;
  final ProvidersService _providers;
  final AdminService _admin;

  String? get uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _policy =>
      _db.collection('trustPolicy').doc('current');

  CollectionReference<Map<String, dynamic>> get _oversight =>
      _db.collection('aiOversight');
  CollectionReference<Map<String, dynamic>> get _fraud =>
      _db.collection('fraudReports');
  CollectionReference<Map<String, dynamic>> get _verify =>
      _db.collection('verificationRequests');

  Stream<Map<String, dynamic>?> watchPolicy() {
    return _policy.snapshots().map((s) => s.data());
  }

  Stream<List<OversightCase>> watchOversight({required bool moderator}) {
    final id = uid;
    if (id == null) return Stream.value(const []);
    final query = moderator
        ? _oversight.snapshots()
        : _oversight.where('uid', isEqualTo: id).snapshots();
    return query.map((snap) {
      final list = snap.docs.map(_caseFrom).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<Map<String, dynamic>>> watchMyFraudReports() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return _fraud.where('uid', isEqualTo: id).snapshots().map((snap) {
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    });
  }

  Stream<List<AccessiblePlace>> watchUnverifiedPlaces() {
    return _places.watchPlaces().map(
      (list) => list.where((p) => !p.verified).toList(),
    );
  }

  Stream<List<ServiceProvider>> watchUnverifiedProviders() {
    return _providers.watchProviders().map(
      (list) => list.where((p) => !p.verified).toList(),
    );
  }

  Stream<bool> watchIsModerator() {
    return _admin.watchConfig().map((c) => c?.isModerator(uid) == true);
  }

  Future<void> ensureSeeded() async {
    await _policy.set({
      'title': 'Responsible AI & trust',
      'body':
          'Ability Link cites mapped places when it can, blocks ableist phrasing, never diagnoses, and queues risky replies for a human. Verification badges are operator-granted. Fraud reports go to moderators — we do not show other users’ accounts here.',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> queueOversight({
    required String prompt,
    required String reply,
    required SafetyScan scan,
  }) async {
    final id = uid;
    if (id == null) return;
    await _oversight.add({
      'uid': id,
      'prompt': prompt,
      'reply': reply,
      'flags': scan.flags,
      'citations': scan.citations,
      'score': scan.score,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reviewCase(String id, {required String status}) async {
    await _oversight.doc(id).update({
      'status': status,
      'reviewerUid': uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> requestVerification({
    required String targetType,
    required String targetId,
    required String name,
  }) async {
    final id = uid;
    if (id == null) throw StateError('Sign in required');
    await _verify.add({
      'uid': id,
      'targetType': targetType,
      'targetId': targetId,
      'name': name,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportFraud({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    final id = uid;
    if (id == null) throw StateError('Sign in required');
    await _fraud.add({
      'uid': id,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason.trim(),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  OversightCase _caseFrom(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final ts = d['createdAt'];
    return OversightCase(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      prompt: (d['prompt'] as String?) ?? '',
      reply: (d['reply'] as String?) ?? '',
      flags: List<String>.from(d['flags'] as List? ?? const []),
      citations: List<String>.from(d['citations'] as List? ?? const []),
      status: (d['status'] as String?) ?? 'pending',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
