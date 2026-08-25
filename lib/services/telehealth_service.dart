import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/telehealth.dart';
import '../models/user_profile.dart';
import 'notification_service.dart';

class TelehealthService {
  TelehealthService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? _userCol(String name) {
    final id = uid;
    if (id == null) return null;
    return _db.collection('users').doc(id).collection(name);
  }

  Stream<List<HealthVital>> watchVitals() {
    final col = _userCol('healthVitals');
    if (col == null) return Stream.value(const []);
    return col.snapshots().map((snap) {
      final list = snap.docs.map(HealthVital.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<MedicalHistoryItem>> watchHistory() {
    final col = _userCol('medicalHistory');
    if (col == null) return Stream.value(const []);
    return col.snapshots().map((snap) {
      final list = snap.docs.map(MedicalHistoryItem.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<Prescription>> watchPrescriptions() {
    final col = _userCol('prescriptions');
    if (col == null) return Stream.value(const []);
    return col.snapshots().map((snap) {
      final list = snap.docs.map(Prescription.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<MedicalDocument>> watchDocuments({String? kind}) {
    final col = _userCol('medicalDocuments');
    if (col == null) return Stream.value(const []);
    return col.snapshots().map((snap) {
      var list = snap.docs.map(MedicalDocument.fromDoc).toList();
      if (kind != null) list = list.where((d) => d.kind == kind).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<DoctorNote>> watchNotes() {
    final col = _userCol('doctorNotes');
    if (col == null) return Stream.value(const []);
    return col.snapshots().map((snap) {
      final list = snap.docs.map(DoctorNote.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<MedReminder>> watchReminders() {
    final col = _userCol('medReminders');
    if (col == null) return Stream.value(const []);
    return col.snapshots().map((s) => s.docs.map(MedReminder.fromDoc).toList());
  }

  Future<void> addVital({
    required int heartRate,
    required int systolic,
    required int diastolic,
    required double weightKg,
    required double sleepHours,
    String note = '',
  }) async {
    final col = _userCol('healthVitals');
    if (col == null) throw StateError('Sign in required');
    await col.add({
      'heartRate': heartRate,
      'systolic': systolic,
      'diastolic': diastolic,
      'weightKg': weightKg,
      'sleepHours': sleepHours,
      'note': note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addHistory({
    required String kind,
    required String title,
    String detail = '',
  }) async {
    final col = _userCol('medicalHistory');
    if (col == null) throw StateError('Sign in required');
    await col.add({
      'kind': kind,
      'title': title.trim(),
      'detail': detail.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addPrescription({
    required String name,
    required String dose,
    required String frequency,
    required String prescriber,
    String notes = '',
  }) async {
    final col = _userCol('prescriptions');
    if (col == null) throw StateError('Sign in required');
    await col.add({
      'name': name.trim(),
      'dose': dose.trim(),
      'frequency': frequency.trim(),
      'prescriber': prescriber.trim(),
      'active': true,
      'notes': notes.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    final id = uid;
    if (id != null) {
      await NotificationService(db: _db, auth: _auth).notify(
        uid: id,
        type: 'prescription',
        title: 'Prescription saved',
        body: '${name.trim()} · ${dose.trim()}',
      );
    }
  }

  Future<void> setPrescriptionActive(String id, bool active) async {
    final col = _userCol('prescriptions');
    if (col == null) throw StateError('Sign in required');
    await col.doc(id).update({'active': active});
  }

  Future<void> addDocument({
    required String title,
    required String kind,
    String detail = '',
    String fileUrl = '',
    String fileName = '',
    String contentType = '',
    String storagePath = '',
  }) async {
    final col = _userCol('medicalDocuments');
    if (col == null) throw StateError('Sign in required');
    await col.add({
      'title': title.trim(),
      'kind': kind,
      'detail': detail.trim(),
      'fileUrl': fileUrl,
      'fileName': fileName,
      'contentType': contentType,
      'storagePath': storagePath,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> uploadDocument({
    required String title,
    required String kind,
    String detail = '',
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  }) async {
    final col = _userCol('medicalDocuments');
    if (col == null) throw StateError('Sign in required');
    if (bytes.length > 15 * 1024 * 1024) {
      throw StateError('File must be under 15 MB');
    }
    final type = contentType.isEmpty
        ? (fileName.toLowerCase().endsWith('.pdf')
              ? 'application/pdf'
              : 'image/jpeg')
        : contentType;
    if (!type.startsWith('image/') && type != 'application/pdf') {
      throw StateError('Use a photo or PDF');
    }
    final ref = col.doc();
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = 'users/$uid/medicalDocuments/${ref.id}/$safeName';
    await FirebaseStorage.instance
        .ref(path)
        .putData(bytes, SettableMetadata(contentType: type));
    final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
    await ref.set({
      'title': title.trim().isEmpty ? fileName : title.trim(),
      'kind': kind,
      'detail': detail.trim(),
      'fileUrl': url,
      'fileName': fileName,
      'contentType': type,
      'storagePath': path,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addNote({
    required String author,
    required String body,
    String appointmentId = '',
  }) async {
    final col = _userCol('doctorNotes');
    if (col == null) throw StateError('Sign in required');
    await col.add({
      'author': author.trim(),
      'body': body.trim(),
      'appointmentId': appointmentId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addReminder({
    required String title,
    required String whenLabel,
    String kind = 'medicine',
    int? hour,
    int? minute,
  }) async {
    final col = _userCol('medReminders');
    if (col == null) throw StateError('Sign in required');
    await col.add({
      'title': title.trim(),
      'whenLabel': whenLabel.trim(),
      'kind': kind,
      'hour': ?hour,
      'minute': ?minute,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final id = uid;
    if (id != null) {
      await NotificationService(db: _db, auth: _auth).notify(
        uid: id,
        type: 'reminder',
        title: title.trim(),
        body: whenLabel.trim(),
      );
    }
  }

  Future<void> saveInsurance({
    required String provider,
    required String memberId,
    required String plan,
  }) async {
    final id = uid;
    if (id == null) throw StateError('Sign in required');
    await _db.collection('users').doc(id).update({
      'healthcare.insurance': provider.trim(),
      'healthcare.insuranceMemberId': memberId.trim(),
      'healthcare.insurancePlan': plan.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await addDocument(
      title: provider.trim().isEmpty ? 'Insurance card' : provider.trim(),
      kind: 'insurance',
      detail: [
        if (plan.trim().isNotEmpty) plan.trim(),
        if (memberId.trim().isNotEmpty) 'Member $memberId',
      ].join(' · '),
    );
  }

  /// First-open records from Passport / healthcare onboarding.
  Future<void> ensureUserSeed(UserProfile? profile) async {
    if (uid == null) return;
    final vitals = _userCol('healthVitals');
    final history = _userCol('medicalHistory');
    final rx = _userCol('prescriptions');
    final docs = _userCol('medicalDocuments');
    final reminders = _userCol('medReminders');
    if (vitals == null ||
        history == null ||
        rx == null ||
        docs == null ||
        reminders == null) {
      return;
    }

    if ((await vitals.limit(1).get()).docs.isEmpty) {
      await vitals.add({
        'heartRate': 72,
        'systolic': 120,
        'diastolic': 80,
        'weightKg': 68,
        'sleepHours': 7.2,
        'note': 'Baseline check-in',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if ((await history.limit(1).get()).docs.isEmpty) {
      final hc = profile?.healthcare ?? const {};
      Future<void> add(String kind, String? raw) async {
        final t = (raw ?? '').trim();
        if (t.isEmpty) return;
        await history.add({
          'kind': kind,
          'title': t,
          'detail': 'From Accessibility Passport',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await add('condition', hc['conditions'] as String?);
      await add('allergy', hc['allergies'] as String?);
      if (profile != null && profile.accessibilityProfiles.isNotEmpty) {
        await history.add({
          'kind': 'other',
          'title': 'Access needs',
          'detail': profile.accessibilityProfiles.join(', '),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if ((await history.limit(1).get()).docs.isEmpty) {
        await history.add({
          'kind': 'condition',
          'title': 'No conditions on file',
          'detail': 'Add conditions, allergies, or surgeries anytime.',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    if ((await rx.limit(1).get()).docs.isEmpty) {
      final meds =
          (profile?.healthcare['medications'] as String?)?.trim() ?? '';
      if (meds.isNotEmpty) {
        await rx.add({
          'name': meds,
          'dose': 'As prescribed',
          'frequency': 'See label',
          'prescriber':
              (profile?.healthcare['doctor'] as String?)?.trim() ??
              'Your physician',
          'active': true,
          'notes': 'Imported from Passport',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await rx.add({
          'name': 'No active prescriptions',
          'dose': '—',
          'frequency': 'Add one after a consult',
          'prescriber': '—',
          'active': false,
          'notes': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    if ((await docs.limit(1).get()).docs.isEmpty) {
      await docs.add({
        'title': 'Welcome visit summary',
        'kind': 'visit',
        'detail': 'Placeholder until you complete a telehealth visit.',
        'createdAt': FieldValue.serverTimestamp(),
      });
      final ins = (profile?.healthcare['insurance'] as String?)?.trim() ?? '';
      if (ins.isNotEmpty) {
        await docs.add({
          'title': ins,
          'kind': 'insurance',
          'detail': 'From Passport healthcare profile',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    if ((await reminders.limit(1).get()).docs.isEmpty) {
      await reminders.add({
        'title': 'Take morning medication',
        'whenLabel': 'Daily, 08:00',
        'kind': 'medicine',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
