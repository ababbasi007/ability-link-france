import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/accessibility_audit.dart';
import '../models/place.dart';
import 'audit_place_promotion.dart';
import 'places_service.dart';
import 'user_activity_service.dart';

class AuditService {
  AuditService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    PlacesService? places,
  }) : _db = db ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _places = places ?? PlacesService();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final PlacesService _places;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('audits');

  String? get uid => _auth.currentUser?.uid;

  String get auditorName {
    final u = _auth.currentUser;
    return u?.displayName?.trim().isNotEmpty == true
        ? u!.displayName!.trim()
        : (u?.email ?? 'Auditor');
  }

  Stream<List<AccessibilityAudit>> watchMine() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return _col.where('uid', isEqualTo: id).snapshots().map((snap) {
      final list = snap.docs.map(AccessibilityAudit.fromDoc).toList();
      list.sort((a, b) {
        final at =
            a.updatedAt ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bt =
            b.updatedAt ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return list;
    });
  }

  Stream<List<AccessibilityAudit>> watchSubmitted({String? placeId}) {
    return _col.where('status', isEqualTo: 'submitted').snapshots().map((snap) {
      var list = snap.docs.map(AccessibilityAudit.fromDoc).toList();
      if (placeId != null && placeId.isNotEmpty) {
        list = list.where((a) => a.placeId == placeId).toList();
      }
      list.sort((a, b) {
        final at =
            a.submittedAt ??
            a.updatedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bt =
            b.submittedAt ??
            b.updatedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return list;
    });
  }

  Stream<AccessibilityAudit?> watchLatestForPlace(String placeId) {
    return watchSubmitted(
      placeId: placeId,
    ).map((list) => list.isEmpty ? null : list.first);
  }

  Future<AccessibilityAudit?> getAudit(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return AccessibilityAudit.fromDoc(doc);
  }

  AccessibilityAudit newDraft({AccessiblePlace? place}) {
    final id = uid;
    if (id == null) {
      throw StateError('Sign in to start an accessibility audit');
    }
    return AccessibilityAudit(
      id: '',
      uid: id,
      auditorName: auditorName,
      placeId: place?.id ?? '',
      placeName: place?.name ?? '',
      placeAddress: place?.address ?? '',
      category: place?.category ?? '',
    );
  }

  Future<String> saveDraft(AccessibilityAudit audit) async {
    final id = uid;
    if (id == null) throw StateError('Sign in required');
    final scored = AccessibilityAudit.compute(audit.answers);
    final payload = {
      ...audit.toMap(),
      'uid': id,
      'auditorName': auditorName,
      'status': 'draft',
      'score': scored.score,
      'sectionScores': scored.sections,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (audit.id.isEmpty) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      final ref = await _col.add(payload);
      return ref.id;
    }
    await _col.doc(audit.id).set(payload, SetOptions(merge: true));
    return audit.id;
  }

  Future<void> submit(AccessibilityAudit audit) async {
    final id = uid;
    if (id == null) throw StateError('Sign in required');
    if (audit.placeName.trim().isEmpty) {
      throw StateError('Add basic place information before submitting');
    }
    if (audit.confirmed != true) {
      throw StateError('Confirm the information is accurate before submitting');
    }
    final scored = AccessibilityAudit.compute(audit.answers);
    if (scored.score == 0 && audit.answeredCount() == 0) {
      throw StateError('Answer at least one checklist item before submitting');
    }
    var docId = audit.id;
    final payload = {
      ...audit.toMap(),
      'uid': id,
      'auditorName': auditorName,
      'status': 'submitted',
      'score': scored.score,
      'sectionScores': scored.sections,
      'updatedAt': FieldValue.serverTimestamp(),
      'submittedAt': FieldValue.serverTimestamp(),
    };
    if (docId.isEmpty) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      final ref = await _col.add(payload);
      docId = ref.id;
    } else {
      await _col.doc(docId).set(payload, SetOptions(merge: true));
    }
    await _applyToPlace(
      audit.copyWith(
        id: docId,
        score: scored.score,
        sectionScores: scored.sections,
      ),
    );
  }

  Future<void> _applyToPlace(AccessibilityAudit audit) async {
    final placeId = audit.placeId.trim();
    if (placeId.isEmpty) return;
    final place = await _places.getPlace(placeId);
    if (place == null) return;
    final previousScore = place.score;
    final patch = AuditPlacePromotion.buildPlaceUpdate(
      audit: audit,
      place: place,
    );
    patch['lastAuditAt'] = FieldValue.serverTimestamp();
    if (audit.id.isNotEmpty) patch['lastAuditId'] = audit.id;
    try {
      await _db.collection('places').doc(placeId).update(patch);
      final nextScore = (patch['score'] as num?)?.toInt() ?? previousScore;
      if (nextScore > previousScore) {
        await UserActivityService().recordScoreImprovement(
          placeId: placeId,
          placeName: place.name,
          fromScore: previousScore,
          toScore: nextScore,
        );
      }
    } catch (_) {
      // Listing still stores the audit even if place merge is denied.
    }
  }

  Future<int> ensureSeeded() async {
    final existing = await _col.doc('seed-city-hospital').get();
    if (existing.exists) return 0;
    final answers = <String, String>{
      for (final section in AuditCatalog.checklist)
        for (final item in AuditCatalog.togglesOf(section))
          '${section.id}.${item.id}': 'yes',
    };
    answers['hearing.signLanguage'] = 'no';
    answers['cognitive.crowding'] = 'na';
    final scored = AccessibilityAudit.compute(answers);
    await _col.doc('seed-city-hospital').set({
      'uid': 'seed-audit-hospital',
      'auditorName': 'Ability Link field team',
      'placeId': 'city-hospital',
      'placeName': 'City Hospital',
      'placeAddress': '525 E 68th St, New York, NY',
      'category': 'Hospital',
      'phone': '+1 212-555-0100',
      'hours': 'Open 24 hours',
      'website': 'https://example.org/city-hospital',
      'gps': '40.7690, -73.9542',
      'confirmed': true,
      'status': 'submitted',
      'answers': answers,
      'sectionNotes': {
        'parking': 'Van spaces at the east garage, level 1.',
        'toilet': 'Changing Places room on the ground floor.',
      },
      'photos': [
        {
          'uri':
              'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=800&h=480&fit=crop',
          'caption': 'Step-free main entrance',
        },
        {
          'uri':
              'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=800&h=480&fit=crop',
          'caption': 'Accessible reception desk',
        },
      ],
      'measurements': {
        'doorWidthCm': '96',
        'rampSlopePercent': '5',
        'corridorWidthCm': '180',
        'parkingWidthCm': '260',
        'stallWidthCm': '165',
        'stallDepthCm': '170',
        'grabBarHeightCm': '86',
        'counterHeightCm': '76',
      },
      'auditorNotes':
          'Fully accessible hospital. Book ASL 48h ahead. Quiet room near imaging.',
      'score': scored.score,
      'sectionScores': scored.sections,
      'seeded': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'submittedAt': FieldValue.serverTimestamp(),
    });
    await _applySeedAuditToPlace();
    return 1;
  }

  Future<void> _applySeedAuditToPlace() async {
    final doc = await _col.doc('seed-city-hospital').get();
    if (!doc.exists) return;
    final audit = AccessibilityAudit.fromDoc(doc);
    await _applyToPlace(audit);
  }
}
