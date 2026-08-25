import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/passport_share.dart';
import '../models/user_profile.dart';

class PassportShareService {
  PassportShareService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const fieldOptions = [
    ('identity', 'Name, Passport ID, language'),
    ('accessibility', 'Needs, mobility aid, assistance'),
    ('communication', 'Communication: sign language, interpreter, contact'),
    ('emergency', 'Emergency contact'),
    ('healthcare', 'Blood group and conditions'),
    ('city', 'City only (not full address)'),
  ];

  CollectionReference<Map<String, dynamic>> get _shares =>
      _db.collection('passportShares');
  CollectionReference<Map<String, dynamic>> get _logs =>
      _db.collection('passportAccessLogs');

  Stream<List<PassportShare>> watchMyShares() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _shares.where('ownerUid', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(PassportShare.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<PassportAccessEvent>> watchMyAccessLog() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _logs.where('ownerUid', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(PassportAccessEvent.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<PassportShare> createShare({
    required UserProfile profile,
    required Set<String> fields,
    required bool consent,
    Duration lifetime = const Duration(days: 7),
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to share your Passport');
    if (!consent) {
      throw StateError('Consent is required to create a share link');
    }
    if (fields.isEmpty) throw StateError('Select at least one field');

    final id = _code();
    final snapshot = buildSnapshot(profile, fields);
    await _shares.doc(id).set({
      'ownerUid': user.uid,
      'fields': fields.toList(),
      'status': 'active',
      'consent': true,
      'snapshot': snapshot,
      'accessCount': 0,
      'lastViewer': '',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(lifetime)),
    });
    await _log(
      ownerUid: user.uid,
      shareId: id,
      action: 'created',
      viewerName: user.displayName ?? 'You',
    );
    final doc = await _shares.doc(id).get();
    return PassportShare.fromDoc(doc);
  }

  Future<void> revoke(String shareId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in required');
    await _shares.doc(shareId).update({
      'status': 'revoked',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _log(
      ownerUid: user.uid,
      shareId: shareId,
      action: 'revoked',
      viewerName: user.displayName ?? 'You',
    );
  }

  Future<PassportShare?> openShare(String rawCode) async {
    final id = rawCode.trim().toLowerCase().replaceAll(
      'abilitylink://passport/',
      '',
    );
    if (id.isEmpty) return null;
    try {
      final doc = await _shares.doc(id).get();
      if (!doc.exists) return null;
      final share = PassportShare.fromDoc(doc);
      if (!share.isActive) return share;

      final viewer = _auth.currentUser;
      await _shares.doc(id).update({
        'accessCount': FieldValue.increment(1),
        'lastAccessAt': FieldValue.serverTimestamp(),
        'lastViewer': viewer?.displayName ?? viewer?.email ?? 'Someone',
      });
      await _log(
        ownerUid: share.ownerUid,
        shareId: id,
        action: 'viewed',
        viewerName: viewer?.displayName ?? viewer?.email ?? 'Someone',
        viewerUid: viewer?.uid ?? '',
      );
      return share;
    } catch (_) {
      return null;
    }
  }

  Future<void> _log({
    required String ownerUid,
    required String shareId,
    required String action,
    required String viewerName,
    String viewerUid = '',
  }) async {
    await _logs.doc().set({
      'ownerUid': ownerUid,
      'shareId': shareId,
      'action': action,
      'viewerName': viewerName,
      'viewerUid': viewerUid.isEmpty
          ? (_auth.currentUser?.uid ?? '')
          : viewerUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Map<String, dynamic> buildSnapshot(
    UserProfile profile,
    Set<String> fields,
  ) {
    final out = <String, dynamic>{'passportId': profile.passportId};
    if (fields.contains('identity')) {
      out['name'] = profile.displayName;
      out['language'] = profile.preferredLanguage;
    }
    if (fields.contains('accessibility')) {
      out['accessibilityProfiles'] = profile.accessibilityProfiles;
      out['mobilityAid'] = profile.mobilityAid;
      out['needCaregiver'] = profile.needCaregiver;
      out['assistanceNeeds'] = profile.assistanceNeeds;
    }
    if (fields.contains('communication')) {
      out['communicationModes'] = profile.communicationModes;
      out['signLanguage'] = profile.signLanguage;
      out['preferredContactMethod'] = profile.preferredContactMethod;
      out['needsInterpreter'] = profile.needsInterpreter;
      out['needsCaptions'] = profile.needsCaptions;
      out['easyRead'] = profile.easyRead;
      out['communicationNotes'] = profile.communicationNotes;
    }
    if (fields.contains('emergency')) {
      out['emergencyName'] = profile.emergency['name'];
      out['emergencyPhone'] = profile.emergency['phone'];
      out['emergencyRelation'] = profile.emergency['relation'];
    }
    if (fields.contains('healthcare')) {
      out['bloodGroup'] = profile.bloodGroup;
      out['conditions'] = profile.healthcare['conditions'];
      out['allergies'] = profile.healthcare['allergies'];
    }
    if (fields.contains('city')) {
      out['city'] = profile.city;
    }
    return out;
  }

  String exportJson(UserProfile profile, {Set<String>? fields}) {
    final keys =
        fields ??
        {
          'identity',
          'accessibility',
          'communication',
          'emergency',
          'healthcare',
          'city',
        };
    return const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'owner': profile.uid,
      ...buildSnapshot(profile, keys),
    });
  }

  Future<void> requestAccountDeletion() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in required');
    await _db.collection('users').doc(user.uid).set({
      'deletionRequestedAt': FieldValue.serverTimestamp(),
      'onboardingComplete': false,
    }, SetOptions(merge: true));
    try {
      await _db.collection('users').doc(user.uid).delete();
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw StateError(
          'For safety, sign in again and then confirm delete. Your deletion request is already recorded.',
        );
      }
      rethrow;
    }
  }

  String _code() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final rand = Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
