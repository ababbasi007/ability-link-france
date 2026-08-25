import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/emergency.dart';
import '../models/expansion.dart';
import '../models/user_profile.dart';
import 'expansion_service.dart';
import 'location_service.dart';
import 'notification_service.dart';

class EmergencyService {
  EmergencyService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    LocationService? location,
    NotificationService? notifications,
    ExpansionService? expansion,
  }) : _db = db ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _location = location ?? LocationService.instance,
       _notifications = notifications ?? NotificationService(),
       _expansion = expansion ?? ExpansionService();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final LocationService _location;
  final NotificationService _notifications;
  final ExpansionService _expansion;

  CollectionReference<Map<String, dynamic>> contactsRef(String uid) =>
      _db.collection('users').doc(uid).collection('trustedContacts');

  CollectionReference<Map<String, dynamic>> get _sos =>
      _db.collection('sosAlerts');
  CollectionReference<Map<String, dynamic>> get _pins =>
      _db.collection('locationShares');
  CollectionReference<Map<String, dynamic>> get _resources =>
      _db.collection('emergencyResources');

  Market marketFor(UserProfile? profile) {
    final code = _expansion.marketCodeFor(profile);
    return seedMarkets.firstWhere(
      (m) => m.code == code,
      orElse: () => seedMarkets.first,
    );
  }

  Stream<List<TrustedContact>> watchContacts() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return contactsRef(uid).snapshots().map((snap) {
      final list = snap.docs.map(TrustedContact.fromDoc).toList();
      list.sort((a, b) {
        if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
        return a.name.compareTo(b.name);
      });
      return list;
    });
  }

  Stream<List<SosAlert>> watchMySos() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _sos.where('uid', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(SosAlert.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<EmergencyResource>> watchResources() {
    return _resources.snapshots().map(
      (snap) => snap.docs.map(EmergencyResource.fromDoc).toList(),
    );
  }

  List<EmergencyResource> nearbyResources(
    List<EmergencyResource> all, {
    required UserProfile? profile,
    required double lat,
    required double lng,
    int limit = 12,
  }) {
    final code = _expansion.marketCodeFor(profile);
    var list = all.where((r) => r.country == code).toList();
    if (list.isEmpty) list = List.of(all);
    list.sort(
      (a, b) => a.distanceKm(lat, lng).compareTo(b.distanceKm(lat, lng)),
    );
    if (list.length > limit) return list.take(limit).toList();
    return list;
  }

  Future<void> ensureContactsFromPassport(UserProfile profile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final name = (profile.emergency['name'] as String?)?.trim() ?? '';
    final phone = (profile.emergency['phone'] as String?)?.trim() ?? '';
    if (name.isEmpty && phone.isEmpty) return;
    await contactsRef(uid).doc('passport-primary').set({
      'name': name.isEmpty ? 'Emergency contact' : name,
      'phone': phone,
      'relation': (profile.emergency['relation'] as String?) ?? '',
      'isPrimary': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addContact({
    required String name,
    required String phone,
    String relation = '',
    bool isPrimary = false,
    String linkedUid = '',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in required');
    await contactsRef(uid).doc().set({
      'name': name.trim(),
      'phone': phone.trim(),
      'relation': relation.trim(),
      'isPrimary': isPrimary,
      'linkedUid': linkedUid.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateContact({
    required String id,
    required String name,
    required String phone,
    String relation = '',
    bool isPrimary = false,
    String linkedUid = '',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in required');
    await contactsRef(uid).doc(id).set({
      'name': name.trim(),
      'phone': phone.trim(),
      'relation': relation.trim(),
      'isPrimary': isPrimary,
      'linkedUid': linkedUid.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteContact(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in required');
    await contactsRef(uid).doc(id).delete();
  }

  Future<int> ensureResourcesSeeded() async {
    var n = 0;
    for (final r in seedEmergencyResources) {
      final ref = _resources.doc(r.id);
      if ((await ref.get()).exists) continue;
      await ref.set({...r.toMap(), 'seeded': true});
      n++;
    }
    return n;
  }

  Map<String, dynamic> medicalSnapshot(UserProfile profile) => {
    'bloodGroup': profile.bloodGroup,
    'conditions': profile.healthcare['conditions'] ?? '',
    'allergies': profile.healthcare['allergies'] ?? '',
    'medications': profile.healthcare['medications'] ?? '',
    'doctor': profile.healthcare['doctor'] ?? '',
    'hospital': profile.healthcare['hospital'] ?? '',
    'insurance': profile.healthcare['insurance'] ?? '',
    'emergencyNotes': profile.healthcare['emergencyNotes'] ?? '',
  };

  Map<String, dynamic> accessibilitySnapshot(UserProfile profile) => {
    'profiles': profile.accessibilityProfiles,
    'mobilityAid': profile.mobilityAid,
    'needCaregiver': profile.needCaregiver,
    'assistanceNeeds': profile.assistanceNeeds,
    'communication': profile.communicationSummary,
    'signLanguage': profile.signLanguage,
    'needsInterpreter': profile.needsInterpreter,
    'preferredContactMethod': profile.preferredContactMethod,
  };

  String buildSosMessage({
    required UserProfile profile,
    required List<TrustedContact> contacts,
    required double lat,
    required double lng,
    required String mapsUrl,
    required String emergencyNumber,
  }) {
    final medical = medicalSnapshot(profile);
    final access = accessibilitySnapshot(profile);
    final names = contacts
        .map((c) => c.name)
        .where((n) => n.isNotEmpty)
        .join(', ');
    final allergies = '${medical['allergies']}'.trim();
    final meds = '${medical['medications']}'.trim();
    final notes = '${medical['emergencyNotes']}'.trim();
    final profiles = (access['profiles'] as List).join(', ');
    final aid = '${access['mobilityAid']}'.trim();

    final lines = <String>[
      'SOS from ${profile.displayName} (${profile.passportId}). I need help.',
      'Location: $mapsUrl',
      'Call emergency services: $emergencyNumber',
      if (profiles.isNotEmpty) 'Accessibility: $profiles',
      if (aid.isNotEmpty) 'Mobility aid: $aid',
      if (profile.needCaregiver) 'Needs caregiver: yes',
      if (profile.needsInterpreter || profile.signLanguage != 'None')
        'Communication: ${profile.communicationSummary}',
      if ('${medical['bloodGroup']}' != '—') 'Blood: ${medical['bloodGroup']}',
      if (allergies.isNotEmpty) 'Allergies: $allergies',
      if (meds.isNotEmpty) 'Medications: $meds',
      if (notes.isNotEmpty) 'Notes: $notes',
      if (names.isNotEmpty) 'Alert: $names',
    ];
    return lines.join('\n');
  }

  Future<({SosAlert alert, String copyText, String mapsUrl})> triggerSos({
    required UserProfile profile,
    required List<TrustedContact> contacts,
    bool notifyContacts = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to send SOS');
    final loc = await _location.refresh();
    final maps = 'https://maps.google.com/?q=${loc.lat},${loc.lng}';
    final market = marketFor(profile);
    final message = buildSosMessage(
      profile: profile,
      contacts: contacts,
      lat: loc.lat,
      lng: loc.lng,
      mapsUrl: maps,
      emergencyNumber: market.emergencyNumber,
    );
    final notified = contacts
        .map((c) => c.linkedUid)
        .where((id) => id.isNotEmpty && id != user.uid)
        .toSet()
        .toList();
    final medical = medicalSnapshot(profile);
    final access = accessibilitySnapshot(profile);
    final ref = _sos.doc();
    await ref.set({
      'uid': user.uid,
      'lat': loc.lat,
      'lng': loc.lng,
      'mapsUrl': maps,
      'message': message,
      'status': 'open',
      'emergencyNumber': market.emergencyNumber,
      'contactNames': contacts.map((c) => c.name).toList(),
      'contactPhones': contacts.map((c) => c.phone).toList(),
      'notifiedUids': notified,
      'medical': medical,
      'accessibility': access,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _notifications.notify(
      uid: user.uid,
      type: 'sos',
      title: 'SOS sent',
      body: 'Your emergency alert is open. Location shared.',
      relatedId: ref.id,
    );
    if (notifyContacts) {
      for (final id in notified) {
        await _notifications.notify(
          uid: id,
          type: 'sos',
          title: 'SOS from ${profile.displayName}',
          body: 'Open Ability Link Emergency. Location: $maps',
          relatedId: ref.id,
        );
      }
    }

    return (
      alert: SosAlert(
        id: ref.id,
        uid: user.uid,
        lat: loc.lat,
        lng: loc.lng,
        message: message,
        createdAt: DateTime.now(),
        mapsUrl: maps,
        medical: medical,
        accessibility: access,
        contactNames: contacts.map((c) => c.name).toList(),
        notifiedUids: notified,
      ),
      copyText: message,
      mapsUrl: maps,
    );
  }

  Future<void> cancelSos(String id) async {
    await _sos.doc(id).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<LocationSharePin> shareLocation({UserProfile? profile}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to share location');
    final loc = await _location.refresh();
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final rand = Random.secure();
    final id = List.generate(
      6,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
    final expires = DateTime.now().add(const Duration(hours: 2));
    await _pins.doc(id).set({
      'uid': user.uid,
      'lat': loc.lat,
      'lng': loc.lng,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expires),
    });
    await _notifications.notify(
      uid: user.uid,
      type: 'sos',
      title: 'Location shared',
      body: 'Code ${id.toUpperCase()} is active for 2 hours.',
      relatedId: id,
    );
    return LocationSharePin(
      id: id,
      uid: user.uid,
      lat: loc.lat,
      lng: loc.lng,
      expiresAt: expires,
      status: 'active',
    );
  }

  String locationShareMessage(LocationSharePin pin, UserProfile profile) =>
      '${profile.displayName} (${profile.passportId}) shared live emergency location. '
      'Code ${pin.id.toUpperCase()} (2h). Map: ${pin.mapsUrl}';

  Future<LocationSharePin?> openLocationShare(String code) async {
    final id = code.trim().toLowerCase();
    if (id.isEmpty) return null;
    try {
      final doc = await _pins.doc(id).get();
      if (!doc.exists) return null;
      return LocationSharePin.fromDoc(doc);
    } catch (_) {
      return null;
    }
  }

  Future<void> revokeLocationShare(String id) async {
    await _pins.doc(id).update({'status': 'revoked'});
  }
}

final seedEmergencyResources = <EmergencyResource>[
  EmergencyResource(
    id: 'er-fr-samu',
    name: 'SAMU (medical emergency)',
    kind: 'hospital',
    phone: '15',
    lat: 48.8566,
    lng: 2.3522,
    stepFree: true,
    country: 'FR',
    summary: 'Urgences médicales 15. Numéro unique européen 112.',
  ),
  EmergencyResource(
    id: 'er-fr-112',
    name: 'European emergency 112',
    kind: 'hospital',
    phone: '112',
    lat: 48.8600,
    lng: 2.3400,
    stepFree: true,
    country: 'FR',
    summary: 'Police, fire, and ambulance. Works from any EU mobile.',
  ),
  EmergencyResource(
    id: 'er-fr-police',
    name: 'Police secours',
    kind: 'police',
    phone: '17',
    lat: 48.8546,
    lng: 2.3470,
    stepFree: true,
    country: 'FR',
    summary: 'Police emergency 17. Prefecture reception is step-free.',
  ),
  EmergencyResource(
    id: 'er-fr-pompiers',
    name: 'Sapeurs-pompiers',
    kind: 'hospital',
    phone: '18',
    lat: 48.8635,
    lng: 2.3508,
    stepFree: true,
    country: 'FR',
    summary: 'Fire and rescue 18. Ambulance when SAMU is overloaded.',
  ),
  EmergencyResource(
    id: 'er-fr-114',
    name: 'Relais sourds / hard of hearing 114',
    kind: 'relay',
    phone: '114',
    lat: 48.8580,
    lng: 2.3480,
    stepFree: true,
    country: 'FR',
    summary: 'Emergency SMS/fax/app relay for Deaf and hard-of-hearing people.',
  ),
  EmergencyResource(
    id: 'er-fr-pharmacie-garde',
    name: 'Pharmacie de garde (Paris centre)',
    kind: 'pharmacy',
    phone: '3237',
    lat: 48.8578,
    lng: 2.3467,
    stepFree: true,
    country: 'FR',
    summary:
        'On-call pharmacy lookup (3237) and nearby late-hour pickup support.',
  ),
  EmergencyResource(
    id: 'er-fr-pitie',
    name: 'AP-HP Pitié-Salpêtrière ER',
    kind: 'hospital',
    phone: '01 42 16 00 00',
    lat: 48.8372,
    lng: 2.3631,
    stepFree: true,
    country: 'FR',
    summary: 'Major Paris ER. Step-free entrance · accessible parking.',
  ),
  EmergencyResource(
    id: 'er-fr-hegp',
    name: 'Hôpital Européen Georges-Pompidou ER',
    kind: 'hospital',
    phone: '01 56 09 20 00',
    lat: 48.8389,
    lng: 2.2739,
    stepFree: true,
    country: 'FR',
    summary: 'Step-free ER, 15e arrondissement.',
  ),
  EmergencyResource(
    id: 'er-fr-hotel-dieu',
    name: 'Hôtel-Dieu ER',
    kind: 'hospital',
    phone: '01 42 34 82 34',
    lat: 48.8540,
    lng: 2.3480,
    stepFree: true,
    country: 'FR',
    summary: 'Central Paris emergency intake near Notre-Dame.',
  ),
  EmergencyResource(
    id: 'er-city-hospital',
    name: 'City Hospital ER',
    kind: 'hospital',
    phone: '911',
    lat: 40.7690,
    lng: -73.9542,
    stepFree: true,
    country: 'US',
    summary: 'Step-free ER entrance. Accessible parking in the hospital lot.',
  ),
  EmergencyResource(
    id: 'er-midtown-pharmacy',
    name: 'Midtown 24h accessible pharmacy',
    kind: 'pharmacy',
    phone: '212-555-0199',
    lat: 40.7575,
    lng: -73.9838,
    stepFree: true,
    country: 'US',
    summary:
        '24-hour pharmacy with step-free entrance and prescription support.',
  ),
  EmergencyResource(
    id: 'er-midtown-police',
    name: 'Midtown accessible precinct desk',
    kind: 'police',
    phone: '911',
    lat: 40.7549,
    lng: -73.9840,
    stepFree: true,
    country: 'US',
    summary: 'Public desk with ramp. Call 911 first if you are in danger.',
  ),
  EmergencyResource(
    id: 'er-access-shelter',
    name: 'Access overnight shelter',
    kind: 'shelter',
    phone: '311',
    lat: 40.7505,
    lng: -73.9910,
    stepFree: true,
    country: 'US',
    summary: 'Wheelchair-accessible shelter intake. Call 311 to confirm a bed.',
  ),
  EmergencyResource(
    id: 'er-relay',
    name: 'Relay / captioned emergency assist',
    kind: 'relay',
    phone: '711',
    lat: 40.758,
    lng: -73.9855,
    stepFree: true,
    country: 'US',
    summary: 'TTY/relay for callers who are Deaf or hard of hearing.',
  ),
  EmergencyResource(
    id: 'er-gb-999',
    name: 'NHS 999 / 111 accessible intake',
    kind: 'hospital',
    phone: '999',
    lat: 51.5074,
    lng: -0.1278,
    stepFree: true,
    country: 'GB',
    summary: 'Life-threatening 999. Non-urgent 111. Text relay 18000.',
  ),
  EmergencyResource(
    id: 'er-es-112',
    name: 'Emergencias 112',
    kind: 'hospital',
    phone: '112',
    lat: 40.4168,
    lng: -3.7038,
    stepFree: true,
    country: 'ES',
    summary: 'Número único 112. Servicio de relé 900 504 061.',
  ),
  EmergencyResource(
    id: 'er-ae-999',
    name: 'Dubai Police / ambulance 999',
    kind: 'hospital',
    phone: '999',
    lat: 25.2048,
    lng: 55.2708,
    stepFree: true,
    country: 'AE',
    summary: 'Police and ambulance 999.',
  ),
  EmergencyResource(
    id: 'er-pk-15',
    name: 'Rescue 1122 / police 15',
    kind: 'hospital',
    phone: '15',
    lat: 31.5204,
    lng: 74.3587,
    stepFree: true,
    country: 'PK',
    summary: 'Police 15. Rescue 1122 for ambulance and fire in many cities.',
  ),
];
