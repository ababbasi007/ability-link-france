import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/care_appointment.dart';
import '../models/service_provider.dart';
import '../utils/remote_image_url.dart';
import 'billing_service.dart';
import 'notification_service.dart';
import 'providers_service.dart';

class HealthcareService {
  HealthcareService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    ProvidersService? providers,
  }) : _db = db ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _providers = providers ?? ProvidersService();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final ProvidersService _providers;

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _db.collection('appointments');
  CollectionReference<Map<String, dynamic>> get _referrals =>
      _db.collection('referrals');

  Future<CareAppointment?> getAppointment(String id) async {
    final snap = await _appointments.doc(id).get();
    if (!snap.exists) return null;
    return CareAppointment.fromDoc(snap);
  }

  Stream<List<CareAppointment>> watchAppointments({String? kind}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _appointments.where('uid', isEqualTo: uid).snapshots().map((snap) {
      var list = snap.docs.map(CareAppointment.fromDoc).toList();
      if (kind != null) {
        list = list.where((a) => a.kind == kind).toList();
      }
      list.sort((a, b) => a.startAt.compareTo(b.startAt));
      return list;
    });
  }

  Stream<List<CareReferral>> watchReferrals() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _referrals.where('uid', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(CareReferral.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<String> book({
    required ServiceProvider provider,
    required DateTime startAt,
    required String mode,
    String notes = '',
    int durationMin = 30,
    bool payNow = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to book');
    final kind = switch (provider.category) {
      'rehab' => 'rehab',
      _ => mode == 'in-clinic' ? 'clinic' : 'telehealth',
    };
    final code = _newJoinCode();
    final ref = _appointments.doc();
    final priceCents =
        (provider.priceFrom <= 0 ? 25 : provider.priceFrom) * 100;
    var paymentStatus = 'unpaid';
    var invoiceId = '';
    if (payNow) {
      final type = kind == 'rehab' ? 'rehab' : 'telehealth';
      invoiceId = await BillingService(db: _db, auth: _auth).payService(
        type: type,
        description:
            '${kind == 'rehab' ? 'Rehab' : 'Visit'} · ${provider.name}',
        amountCents: priceCents,
        relatedId: ref.id,
      );
      paymentStatus = 'paid';
    }
    await ref.set({
      'uid': user.uid,
      'providerId': provider.id,
      'providerName': provider.name,
      'specialty': provider.specialty,
      'kind': kind,
      'mode': mode,
      'startAt': Timestamp.fromDate(startAt),
      'durationMin': durationMin,
      'status': 'booked',
      'notes': notes,
      'photoUrl': provider.photoUrl,
      'patientName': user.displayName ?? '',
      'joinCode': code,
      'priceCents': priceCents,
      'paymentStatus': paymentStatus,
      'invoiceId': invoiceId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _saveJoinCode(
      code: code,
      appointmentId: ref.id,
      uid: user.uid,
      provider: provider,
      mode: mode,
      kind: kind,
      startAt: startAt,
      patientName: user.displayName ?? 'Patient',
      photoUrl: provider.photoUrl,
      notes: notes,
    );
    await NotificationService(db: _db, auth: _auth).notifyBooking(
      patientUid: user.uid,
      providerName: provider.name,
      appointmentId: ref.id,
      ownerUid: provider.ownerUid,
      kind: kind,
    );
    return ref.id;
  }

  Future<void> reschedule(String id, DateTime startAt) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in required');
    await _appointments.doc(id).update({
      'startAt': Timestamp.fromDate(startAt),
      'status': 'booked',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final snap = await _appointments.doc(id).get();
    final name = (snap.data()?['providerName'] as String?) ?? 'your clinician';
    await NotificationService(db: _db, auth: _auth).notify(
      uid: user.uid,
      type: 'appointment',
      title: 'Appointment rescheduled',
      body: 'Your visit with $name was moved.',
      relatedId: id,
    );
  }

  Future<String> bookFollowUp(CareAppointment from, {DateTime? startAt}) async {
    final provider = await _providers.getProvider(from.providerId);
    if (provider == null) throw StateError('Provider not found');
    final when = startAt ?? from.startAt.add(const Duration(days: 14));
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to book');
    final kind = from.kind == 'rehab' ? 'rehab' : 'telehealth';
    final mode = from.isRemote ? from.mode : 'video';
    final code = _newJoinCode();
    final ref = _appointments.doc();
    await ref.set({
      'uid': user.uid,
      'providerId': provider.id,
      'providerName': provider.name,
      'specialty': provider.specialty,
      'kind': kind,
      'mode': mode,
      'startAt': Timestamp.fromDate(when),
      'durationMin': from.durationMin,
      'status': 'booked',
      'notes': 'Follow-up after ${from.whenLabel}',
      'photoUrl': provider.photoUrl,
      'followUpOf': from.id,
      'patientName': user.displayName ?? '',
      'joinCode': code,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _saveJoinCode(
      code: code,
      appointmentId: ref.id,
      uid: user.uid,
      provider: provider,
      mode: mode,
      kind: kind,
      startAt: when,
      patientName: user.displayName ?? 'Patient',
      photoUrl: provider.photoUrl,
      notes: 'Follow-up after ${from.whenLabel}',
    );
    await NotificationService(db: _db, auth: _auth).notifyBooking(
      patientUid: user.uid,
      providerName: provider.name,
      appointmentId: ref.id,
      ownerUid: provider.ownerUid,
      kind: kind,
    );
    return ref.id;
  }

  List<DateTime> slotsFor(ServiceProvider provider, {int count = 8}) {
    final now = DateTime.now();
    final hours = provider.availableNow
        ? const [9, 11, 14, 16]
        : const [11, 16];
    final out = <DateTime>[];
    var day = DateTime(now.year, now.month, now.day);
    while (out.length < count) {
      day = day.add(const Duration(days: 1));
      if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
        continue;
      }
      for (final h in hours) {
        if (out.length >= count) break;
        out.add(DateTime(day.year, day.month, day.day, h));
      }
    }
    return out;
  }

  Future<void> cancel(String id) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in required');
    await _appointments.doc(id).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await NotificationService(db: _db, auth: _auth).notify(
      uid: user.uid,
      type: 'appointment',
      title: 'Appointment cancelled',
      body: 'Your visit was cancelled.',
      relatedId: id,
    );
  }

  Future<void> complete(String id, {String summary = ''}) async {
    final ref = _appointments.doc(id);
    await ref.update({
      'status': 'completed',
      'summary': summary,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final snap = await ref.get();
    final providerId = (snap.data()?['providerId'] as String?) ?? '';
    final providerName = (snap.data()?['providerName'] as String?) ?? '';
    if (providerId.isEmpty) return;
    final provider = await _providers.getProvider(providerId);
    if (provider == null || provider.ownerUid.isEmpty) return;
    await BillingService(db: _db, auth: _auth).recordSessionCommission(
      ownerUid: provider.ownerUid,
      providerName: providerName.isEmpty ? provider.name : providerName,
      appointmentId: id,
    );
  }

  Future<String> requestReferral({
    required String toSpecialty,
    required String reason,
    String fromName = 'Self-referral',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to request a referral');

    await _providers.ensureSeeded();
    final all = await _db.collection('providers').get();
    final match = all.docs
        .map(ServiceProvider.fromDoc)
        .where(
          (p) =>
              p.specialty.toLowerCase().contains(toSpecialty.toLowerCase()) ||
              p.categoryLabel.toLowerCase() == toSpecialty.toLowerCase() ||
              (toSpecialty.toLowerCase().contains('physio') &&
                  p.category == 'rehab') ||
              (toSpecialty.toLowerCase().contains('neuro') &&
                  p.specialty.toLowerCase().contains('neuro')),
        )
        .toList();
    match.sort((a, b) => b.rating.compareTo(a.rating));
    final picked = match.isNotEmpty ? match.first : null;

    final ref = _referrals.doc();
    await ref.set({
      'uid': user.uid,
      'fromName': fromName,
      'toSpecialty': toSpecialty,
      'reason': reason,
      'status': picked == null ? 'requested' : 'matched',
      'matchedProviderId': picked?.id ?? '',
      'matchedProviderName': picked?.name ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// First-run demo visits so Home/Telehealth are not empty.
  Future<void> ensureDemoAppointments() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final existing = await _appointments
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    await _providers.ensureSeeded();
    final sara = await _providers.getProvider('dr-sara-ahmed');
    final james = await _providers.getProvider('pt-james-okonkwo');
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 11);
    final later = DateTime(now.year, now.month, now.day + 3, 16, 30);

    if (sara != null) {
      await book(
        provider: sara,
        startAt: tomorrow,
        mode: 'video',
        notes: 'Captions on, plain-language summary after visit.',
        payNow: false,
      );
    }
    if (james != null) {
      await book(
        provider: james,
        startAt: later,
        mode: 'video',
        notes: 'Wheelchair-adapted session.',
        payNow: false,
        durationMin: 45,
      );
    }
  }

  Future<CareAppointment?> appointmentFromJoinCode(String raw) async {
    final code = raw.trim().toUpperCase();
    if (code.length < 4) return null;
    final snap = await _db.collection('consultJoinCodes').doc(code).get();
    if (!snap.exists) return null;
    final d = snap.data() ?? {};
    final id = (d['appointmentId'] as String?) ?? '';
    if (id.isNotEmpty) {
      try {
        final live = await getAppointment(id);
        if (live != null) return live;
      } catch (_) {}
    }
    final ts = d['startAt'];
    return CareAppointment(
      id: id,
      uid: (d['uid'] as String?) ?? '',
      providerId: (d['providerId'] as String?) ?? '',
      providerName: (d['providerName'] as String?) ?? 'Clinician',
      specialty: (d['specialty'] as String?) ?? '',
      kind: (d['kind'] as String?) ?? 'telehealth',
      mode: (d['mode'] as String?) ?? 'video',
      startAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      durationMin: (d['durationMin'] as num?)?.toInt() ?? 30,
      status: (d['status'] as String?) ?? 'booked',
      notes: (d['notes'] as String?) ?? '',
      photoUrl: sanitizeRemoteImageUrl((d['photoUrl'] as String?) ?? ''),
      patientName: (d['patientName'] as String?) ?? '',
      joinCode: code,
    );
  }

  Future<String> ensureJoinCode(CareAppointment appointment) async {
    if (appointment.joinCode.isNotEmpty) return appointment.joinCode;
    final user = _auth.currentUser;
    if (user == null || user.uid != appointment.uid) {
      return appointment.joinCode;
    }
    final code = _newJoinCode();
    await _appointments.doc(appointment.id).update({'joinCode': code});
    final provider = await _providers.getProvider(appointment.providerId);
    await _saveJoinCode(
      code: code,
      appointmentId: appointment.id,
      uid: appointment.uid,
      provider: provider,
      mode: appointment.mode,
      kind: appointment.kind,
      startAt: appointment.startAt,
      patientName: appointment.patientName.isEmpty
          ? (user.displayName ?? 'Patient')
          : appointment.patientName,
      photoUrl: appointment.photoUrl,
      notes: appointment.notes,
      specialty: appointment.specialty,
    );
    return code;
  }

  /// A clinician joining from another device proves they hold the visit code, so
  /// signaling and chat stay closed to everyone else.
  Future<void> registerConsultGuest({
    required String appointmentId,
    required String code,
  }) async {
    final user = _auth.currentUser;
    if (user == null || appointmentId.isEmpty || code.isEmpty) return;
    await _db
        .collection('consultRooms')
        .doc(appointmentId)
        .collection('guests')
        .doc(user.uid)
        .set({
          'code': code.trim().toUpperCase(),
          'joinedAt': FieldValue.serverTimestamp(),
        });
  }

  String _newJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<void> _saveJoinCode({
    required String code,
    required String appointmentId,
    required String uid,
    required String mode,
    required String kind,
    required DateTime startAt,
    required String patientName,
    required String photoUrl,
    required String notes,
    ServiceProvider? provider,
    String specialty = '',
  }) async {
    await _db.collection('consultJoinCodes').doc(code).set({
      'appointmentId': appointmentId,
      'uid': uid,
      'providerId': provider?.id ?? '',
      'providerName': provider?.name ?? 'Clinician',
      'specialty': specialty.isEmpty ? (provider?.specialty ?? '') : specialty,
      'kind': kind,
      'mode': mode,
      'startAt': Timestamp.fromDate(startAt),
      'durationMin': 30,
      'status': 'booked',
      'notes': notes,
      'photoUrl': photoUrl,
      'patientName': patientName,
      'joinCode': code,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
