import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/accessibility_review.dart';
import '../models/community.dart';
import '../models/place.dart';
import '../models/platform_admin.dart';
import '../models/service_provider.dart';

class AdminService {
  AdminService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _settings =>
      _db.collection('platformConfig').doc('settings');

  Stream<PlatformConfig?> watchConfig() {
    return _settings.snapshots().map((snap) {
      if (!snap.exists) return null;
      return PlatformConfig.fromDoc(snap);
    });
  }

  Stream<List<AdminUserRecord>> watchUsers() {
    return _db.collection('users').snapshots().map((snap) {
      final list = snap.docs.map(AdminUserRecord.fromDoc).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Future<void> setUserStatus({
    required String uid,
    required String accountStatus,
    int? fraudScore,
    String? fraudNotes,
    String? platformRole,
  }) async {
    await _db.collection('users').doc(uid).update({
      'accountStatus': accountStatus,
      if (fraudScore != null) 'fraudScore': fraudScore,
      if (fraudNotes != null) 'fraudNotes': fraudNotes,
      if (platformRole != null) 'platformRole': platformRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ServiceProvider>> watchAllProviders() {
    return _db
        .collection('providers')
        .snapshots()
        .map((snap) => snap.docs.map(ServiceProvider.fromDoc).toList());
  }

  Future<void> setProviderFlags({
    required String id,
    bool? verified,
    bool? hidden,
  }) async {
    await _db.collection('providers').doc(id).update({
      if (verified != null) 'verified': verified,
      if (hidden != null) 'hidden': hidden,
    });
  }

  Stream<List<AccessiblePlace>> watchAllPlaces() {
    return _db
        .collection('places')
        .snapshots()
        .map((snap) => snap.docs.map(AccessiblePlace.fromDoc).toList());
  }

  Future<void> setPlaceFlags({
    required String id,
    bool? hidden,
    bool? verified,
    String? category,
  }) async {
    await _db.collection('places').doc(id).update({
      if (hidden != null) 'hidden': hidden,
      if (verified != null) 'verified': verified,
      if (category != null) 'category': category,
    });
  }

  Stream<List<AccessibilityReview>> watchReviews() {
    return _db
        .collection('reviews')
        .snapshots()
        .map((snap) => snap.docs.map(AccessibilityReview.fromDoc).toList());
  }

  Stream<List<CommunityPost>> watchPosts() {
    return _db
        .collection('communityPosts')
        .snapshots()
        .map((snap) => snap.docs.map(CommunityPost.fromDoc).toList());
  }

  Future<void> setContentStatus({
    required String kind,
    required String id,
    required String status,
  }) async {
    final col = kind == 'review' ? 'reviews' : 'communityPosts';
    await _db.collection(col).doc(id).update({'status': status});
  }

  Future<void> setModerator(String otherUid, {required bool enabled}) async {
    await _settings.update({
      'moderatorUids': enabled
          ? FieldValue.arrayUnion([otherUid])
          : FieldValue.arrayRemove([otherUid]),
    });
    await _db.collection('users').doc(otherUid).update({
      'platformRole': enabled ? 'moderator' : '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveTaxonomy({
    required List<String> placeCategories,
    required List<String> providerCategories,
    required String maintenanceMessage,
  }) async {
    await _settings.update({
      'placeCategories': placeCategories,
      'providerCategories': providerCategories,
      'maintenanceMessage': maintenanceMessage.trim(),
    });
  }
}
