import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/care_appointment.dart';
import '../models/health_org.dart';
import '../models/service_provider.dart';
import '../models/user_profile.dart';

class HealthOrgService {
  HealthOrgService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _orgs =>
      _db.collection('healthOrgs');
  CollectionReference<Map<String, dynamic>> get _consents =>
      _db.collection('patientConsents');
  CollectionReference<Map<String, dynamic>> get _appointments =>
      _db.collection('appointments');
  CollectionReference<Map<String, dynamic>> get _referrals =>
      _db.collection('referrals');

  CollectionReference<Map<String, dynamic>> _staff(String orgId) =>
      _orgs.doc(orgId).collection('staff');

  Stream<HealthOrg?> watchMyOrg() {
    final id = uid;
    if (id == null) return Stream.value(null);
    return _orgs.where('ownerUid', isEqualTo: id).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      return HealthOrg.fromDoc(snap.docs.first);
    });
  }

  Stream<List<HealthOrg>> watchOrgs() {
    return _orgs.snapshots().map((snap) {
      final list = snap.docs.map(HealthOrg.fromDoc).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Stream<List<OrgStaffMember>> watchStaff(String orgId) {
    return _staff(
      orgId,
    ).snapshots().map((snap) => snap.docs.map(OrgStaffMember.fromDoc).toList());
  }

  Stream<List<PatientConsent>> watchConsents(String orgId) {
    return _consents.where('orgId', isEqualTo: orgId).snapshots().map((snap) {
      final list = snap.docs
          .map(PatientConsent.fromDoc)
          .where((c) => c.isActive)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<CareAppointment>> watchOrgAppointments(String orgId) {
    return _appointments.where('orgId', isEqualTo: orgId).snapshots().map((
      snap,
    ) {
      final list = snap.docs.map(CareAppointment.fromDoc).toList();
      list.sort((a, b) => a.startAt.compareTo(b.startAt));
      return list;
    });
  }

  Stream<List<CareReferral>> watchOrgReferrals(String orgId) {
    return _referrals.where('orgId', isEqualTo: orgId).snapshots().map((snap) {
      final list = snap.docs.map(CareReferral.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Map<String, int> needsReport(List<PatientConsent> consents) {
    final counts = <String, int>{};
    for (final c in consents) {
      for (final n in c.needs) {
        final key = n.trim();
        if (key.isEmpty) continue;
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<String> createOrg({
    required String name,
    required String city,
    required String kind,
    required String about,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to register a clinic');
    final existing = await _orgs
        .where('ownerUid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;
    final ref = _orgs.doc();
    await ref.set({
      'name': name.trim(),
      'city': city.trim(),
      'kind': kind,
      'about': about.trim(),
      'ownerUid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> addStaff(String orgId, ServiceProvider provider) async {
    await _staff(orgId).doc(provider.id).set({
      'name': provider.name,
      'specialty': provider.specialty,
      'category': provider.category,
    });
  }

  Future<void> removeStaff(String orgId, String providerId) async {
    await _staff(orgId).doc(providerId).delete();
  }

  Future<void> shareNeeds({
    required HealthOrg org,
    required UserProfile profile,
    String notes = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to share needs');
    final id = '${org.id}_${user.uid}';
    await _consents.doc(id).set({
      'orgId': org.id,
      'uid': user.uid,
      'patientName': profile.displayName,
      'needs': profile.accessibilityProfiles,
      'notes': notes.trim(),
      'consent': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> revokeConsent(String consentId) async {
    await _consents.doc(consentId).update({'status': 'revoked'});
  }

  Future<void> createOrgReferral({
    required String orgId,
    required PatientConsent patient,
    required String toSpecialty,
    required String reason,
    OrgStaffMember? staff,
  }) async {
    await _referrals.doc().set({
      'uid': patient.uid,
      'orgId': orgId,
      'patientName': patient.patientName,
      'fromName': 'Clinic coordinator',
      'toSpecialty': toSpecialty.trim(),
      'reason': reason.trim(),
      'status': staff == null ? 'requested' : 'matched',
      'matchedProviderId': staff?.providerId ?? '',
      'matchedProviderName': staff?.name ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createOrgAppointment({
    required String orgId,
    required PatientConsent patient,
    required OrgStaffMember staff,
    required DateTime startAt,
    String notes = '',
  }) async {
    await _appointments.doc().set({
      'uid': patient.uid,
      'orgId': orgId,
      'patientName': patient.patientName,
      'providerId': staff.providerId,
      'providerName': staff.name,
      'specialty': staff.specialty,
      'kind': staff.category == 'rehab' ? 'rehab' : 'clinic',
      'mode': 'in-clinic',
      'startAt': Timestamp.fromDate(startAt),
      'durationMin': 30,
      'status': 'booked',
      'notes': notes.trim(),
      'photoUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setAppointmentStatus(String id, String status) async {
    await _appointments.doc(id).update({'status': status});
  }

  Future<void> setReferralStatus({
    required String id,
    required String status,
    OrgStaffMember? staff,
  }) async {
    await _referrals.doc(id).update({
      'status': status,
      if (staff != null) 'matchedProviderId': staff.providerId,
      if (staff != null) 'matchedProviderName': staff.name,
    });
  }
}
