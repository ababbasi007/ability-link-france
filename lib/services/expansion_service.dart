import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expansion.dart';
import '../models/user_profile.dart';

class ExpansionService {
  ExpansionService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _markets =>
      _db.collection('markets');
  CollectionReference<Map<String, dynamic>> get _partners =>
      _db.collection('expansionPartners');

  Stream<List<Market>> watchMarkets() {
    return _markets.snapshots().map((snap) {
      final list = snap.docs.map(Market.fromDoc).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Stream<List<ExpansionPartner>> watchPartners({String? marketCode}) {
    return _partners.snapshots().map((snap) {
      var list = snap.docs.map(ExpansionPartner.fromDoc).toList();
      if (marketCode != null && marketCode.isNotEmpty) {
        list = list.where((p) => p.marketCode == marketCode).toList();
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<ExpansionPartner?> watchMyPartner() {
    final id = uid;
    if (id == null) return Stream.value(null);
    return _partners
        .where('ownerUid', isEqualTo: id)
        .limit(1)
        .snapshots()
        .map(
          (snap) => snap.docs.isEmpty
              ? null
              : ExpansionPartner.fromDoc(snap.docs.first),
        );
  }

  String marketCodeFor(UserProfile? profile) {
    final fromPrefs = (profile?.preferences['marketCode'] as String?)?.trim();
    if (fromPrefs != null && fromPrefs.isNotEmpty) return fromPrefs;
    return Market.inferCode(profile?.contact['country'] as String? ?? '');
  }

  Future<void> setMyMarket(String code) async {
    final id = uid;
    if (id == null) throw StateError('Sign in required');
    await _db.collection('users').doc(id).update({
      'preferences.marketCode': code,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> registerPartner({
    required String name,
    required String marketCode,
    required String kind,
    required String summary,
  }) async {
    final id = uid;
    if (id == null) throw StateError('Sign in required');
    final existing = await _partners
        .where('ownerUid', isEqualTo: id)
        .limit(1)
        .get();
    final payload = {
      'ownerUid': id,
      'name': name.trim(),
      'marketCode': marketCode,
      'kind': kind,
      'summary': summary.trim(),
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.set(payload, SetOptions(merge: true));
      return;
    }
    await _partners.add({
      ...payload,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ensureSeeded() async {
    final batch = _db.batch();
    for (final m in seedMarkets) {
      batch.set(_markets.doc(m.code), m.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  List<String> matchingStandards(UserProfile? profile, Market market) {
    final needs = profile?.accessibilityProfiles ?? const <String>[];
    if (needs.isEmpty) return [market.standard];
    return [
      market.standard,
      for (final n in needs.take(3)) '${market.standard} · $n',
    ];
  }
}

const seedMarkets = <Market>[
  Market(
    code: 'US',
    name: 'United States',
    currency: 'USD',
    currencySymbol: '\$',
    emergencyNumber: '911',
    relayNumber: '711',
    standard: 'ADA + WCAG 2.2',
    standardSummary:
        'Americans with Disabilities Act for venues and employment. Digital services follow WCAG 2.2 AA.',
    placeTaxonomy: [
      'hospital',
      'cafe',
      'library',
      'mall',
      'transit',
      'park',
      'other',
    ],
    providerTaxonomy: [
      'healthcare',
      'rehab',
      'education',
      'caregiving',
      'other',
    ],
    languages: ['English', 'Spanish'],
    samplePrice: 120,
  ),
  Market(
    code: 'FR',
    name: 'France',
    currency: 'EUR',
    currencySymbol: '€',
    emergencyNumber: '112',
    relayNumber: '114',
    standard: 'RGAA 4 / loi handicap 2005',
    standardSummary:
        'French public digital services use RGAA. Buildings follow the 2005 disability law and ERP access rules.',
    placeTaxonomy: [
      'hôpital',
      'café',
      'médiathèque',
      'gare',
      'parc',
      'mairie',
      'other',
    ],
    providerTaxonomy: ['santé', 'rééducation', 'éducation', 'aidant', 'other'],
    languages: ['French', 'English'],
    samplePrice: 95,
  ),
  Market(
    code: 'GB',
    name: 'United Kingdom',
    currency: 'GBP',
    currencySymbol: '£',
    emergencyNumber: '999',
    relayNumber: '18000',
    standard: 'Equality Act 2010 + BS 8300',
    standardSummary:
        'Reasonable adjustments under the Equality Act. Built environment often cites BS 8300.',
    placeTaxonomy: ['hospital', 'cafe', 'library', 'station', 'park', 'other'],
    providerTaxonomy: [
      'healthcare',
      'rehab',
      'education',
      'caregiving',
      'other',
    ],
    languages: ['English'],
    samplePrice: 90,
  ),
  Market(
    code: 'ES',
    name: 'Spain',
    currency: 'EUR',
    currencySymbol: '€',
    emergencyNumber: '112',
    relayNumber: '900 504 061',
    standard: 'UNE 170001 / LSSI accessibility',
    standardSummary:
        'DALCO criteria (UNE 170001) for physical access. Public websites follow European EN 301 549.',
    placeTaxonomy: [
      'hospital',
      'cafetería',
      'biblioteca',
      'estación',
      'parque',
      'other',
    ],
    providerTaxonomy: [
      'salud',
      'rehabilitación',
      'educación',
      'cuidados',
      'other',
    ],
    languages: ['Spanish', 'Catalan', 'English'],
    samplePrice: 80,
  ),
  Market(
    code: 'AE',
    name: 'United Arab Emirates',
    currency: 'AED',
    currencySymbol: 'د.إ',
    emergencyNumber: '999',
    relayNumber: '800 1717',
    standard: 'People of Determination / Dubai Universal Design',
    standardSummary:
        'UAE People of Determination policy plus Dubai Universal Design code for buildings and transit.',
    placeTaxonomy: ['hospital', 'cafe', 'mall', 'metro', 'park', 'other'],
    providerTaxonomy: [
      'healthcare',
      'rehab',
      'education',
      'caregiving',
      'other',
    ],
    languages: ['Arabic', 'English'],
    samplePrice: 350,
  ),
  Market(
    code: 'PK',
    name: 'Pakistan',
    currency: 'PKR',
    currencySymbol: 'Rs',
    emergencyNumber: '15',
    relayNumber: '1122',
    standard: 'ICT accessibility + local building bylaws',
    standardSummary:
        'ICT accessibility policy for public digital services. Physical access follows provincial building bylaws.',
    placeTaxonomy: [
      'hospital',
      'cafe',
      'library',
      'mall',
      'transit',
      'park',
      'other',
    ],
    providerTaxonomy: [
      'healthcare',
      'rehab',
      'education',
      'caregiving',
      'other',
    ],
    languages: ['Urdu', 'English'],
    samplePrice: 4500,
  ),
];
