import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transport_option.dart';
import 'notification_service.dart';

class TransportService {
  TransportService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _options =>
      _db.collection('transportOptions');
  CollectionReference<Map<String, dynamic>> get _alerts =>
      _db.collection('barrierAlerts');

  Stream<List<TransportOption>> watchOptions() {
    return _options.snapshots().map(
      (snap) => snap.docs.map(TransportOption.fromDoc).toList(),
    );
  }

  Stream<List<BarrierAlert>> watchAlerts() {
    return _alerts.snapshots().map((snap) {
      final list = snap.docs.map(BarrierAlert.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<int> ensureSeeded() async {
    var n = 0;
    for (final o in seedTransport) {
      final ref = _options.doc(o.id);
      final snap = await ref.get();
      if (snap.exists) continue;
      await ref.set({
        ...o.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      n++;
    }
    for (final a in seedAlerts) {
      final ref = _alerts.doc(a.id);
      final snap = await ref.get();
      if (snap.exists) continue;
      await ref.set({
        'title': a.title,
        'detail': a.detail,
        'severity': a.severity,
        'lat': a.lat,
        'lng': a.lng,
        'status': a.status,
        'uid': 'seed-transit',
        'placeName': a.placeName,
        'seeded': true,
        'createdAt': Timestamp.fromDate(a.createdAt),
      });
      n++;
    }
    return n;
  }

  List<TransportOption> filter(
    List<TransportOption> all, {
    String query = '',
    String kind = 'All',
    bool stepFreeOnly = false,
    double originLat = 40.758,
    double originLng = -73.9855,
  }) {
    var list = all.where((o) {
      if (!o.matchesQuery(query)) return false;
      if (kind != 'All' && o.kind != kind) return false;
      if (stepFreeOnly && !o.stepFree) return false;
      return true;
    }).toList();
    list.sort(
      (a, b) => a
          .distanceKm(originLat, originLng)
          .compareTo(b.distanceKm(originLat, originLng)),
    );
    return list;
  }

  Future<String> reportBarrier({
    required String title,
    required String detail,
    required String severity,
    required double lat,
    required double lng,
    String placeName = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to report a barrier');
    final ref = _alerts.doc();
    await ref.set({
      'uid': user.uid,
      'title': title,
      'detail': detail,
      'severity': severity,
      'lat': lat,
      'lng': lng,
      'placeName': placeName,
      'status': 'open',
      'seeded': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await NotificationService(
      db: _db,
      auth: _auth,
    ).notifyBarrier(title: title, detail: detail, alertId: ref.id);
    return ref.id;
  }

  Future<void> resolveAlert(String id) async {
    await _alerts.doc(id).update({
      'status': 'resolved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final seedTransport = <TransportOption>[
  TransportOption(
    id: 'tx-grand-central',
    kind: 'transit',
    name: 'Grand Central — step-free hub',
    lat: 40.7527,
    lng: -73.9772,
    stepFree: true,
    elevatorStatus: 'in-service',
    verified: true,
    apiHook: 'gtfs-realtime (demo)',
    features: ['Elevator', 'Tactile paving', 'Audio announcements', 'Ramp'],
    summary:
        'Elevators to platform 5 in service. Step-free from 42nd St entrance.',
  ),
  TransportOption(
    id: 'tx-penn',
    kind: 'transit',
    name: 'Penn Station accessible entrance',
    lat: 40.7506,
    lng: -73.9935,
    stepFree: true,
    elevatorStatus: 'unknown',
    verified: true,
    apiHook: 'gtfs-realtime (demo)',
    features: ['Elevator', 'Wide gates'],
    summary:
        'Use 8th Ave elevator bank. Confirm elevator status before travel.',
  ),
  TransportOption(
    id: 'tx-lex-subway',
    kind: 'transit',
    name: 'Lexington Ave / 51 St',
    lat: 40.7571,
    lng: -73.9720,
    stepFree: false,
    elevatorStatus: 'out',
    verified: false,
    apiHook: 'gtfs-realtime (demo)',
    features: ['Stairs only today'],
    summary: 'Elevator outage reported. Use Grand Central for step-free 6/E/M.',
  ),
  TransportOption(
    id: 'tx-bus-m15',
    kind: 'bus',
    name: 'M15 SBS — Accessible stop (1 Ave / 57 St)',
    lat: 40.7605,
    lng: -73.9638,
    stepFree: true,
    verified: true,
    apiHook: 'gtfs-realtime (demo)',
    features: [
      'Kneeling bus',
      'Ramp deployed on request',
      'Audio next-stop',
      'Priority seating',
    ],
    summary:
        'Marked accessible SBS stop with curb ramp and tactile pad. Low-floor buses on this route.',
  ),
  TransportOption(
    id: 'tx-bus-m34',
    kind: 'bus',
    name: 'M34 Select — Accessible stop (34 St / 7 Ave)',
    lat: 40.7508,
    lng: -73.9905,
    stepFree: true,
    verified: true,
    apiHook: 'gtfs-realtime (demo)',
    features: ['Level boarding', 'Shelter', 'Real-time display'],
    summary: 'Level-boarding pad for Select Bus. Shelter with bench and clear aisle.',
  ),
  TransportOption(
    id: 'tx-access-taxi',
    kind: 'taxi',
    name: 'AccessRide WAV taxi',
    lat: 40.758,
    lng: -73.9855,
    stepFree: true,
    verified: true,
    phone: '+1-212-555-0144',
    apiHook: 'wav-taxi-dispatch (demo)',
    features: ['Wheelchair van', 'Caregiver seat', 'Advance booking'],
    summary:
        'Wheelchair-accessible van. Book 30+ minutes ahead. Demo dispatch hook.',
  ),
  TransportOption(
    id: 'tx-midtown-cab',
    kind: 'taxi',
    name: 'Midtown accessible cab stand',
    lat: 40.7549,
    lng: -73.9840,
    stepFree: true,
    verified: false,
    phone: '+1-212-555-0199',
    apiHook: 'wav-taxi-dispatch (demo)',
    features: ['WAV on request', 'Curb ramp'],
    summary: 'Street stand with WAV request. Not all cabs are ramped.',
  ),
  TransportOption(
    id: 'tx-park-34',
    kind: 'parking',
    name: '34th St accessible garage',
    lat: 40.7505,
    lng: -73.9910,
    stepFree: true,
    verified: true,
    spaces: 12,
    apiHook: 'parking-occupancy (demo)',
    features: ['Van spaces', 'Elevator to street', '8-ft aisles'],
    summary: '12 marked van-accessible bays. Elevator to 34th St sidewalk.',
  ),
  TransportOption(
    id: 'tx-park-hospital',
    kind: 'parking',
    name: 'City Hospital accessible lot',
    lat: 40.7690,
    lng: -73.9542,
    stepFree: true,
    verified: true,
    spaces: 18,
    apiHook: 'parking-occupancy (demo)',
    features: ['Van spaces', 'Covered drop-off', 'Step-free to lobby'],
    summary: 'Hospital lot with covered drop-off and step-free lobby path.',
  ),
  TransportOption(
    id: 'tx-ev-park-lex',
    kind: 'ev',
    name: 'Lexington EV — accessible parking bays',
    lat: 40.7588,
    lng: -73.9705,
    stepFree: true,
    verified: true,
    spaces: 4,
    apiHook: 'parking-occupancy (demo)',
    features: [
      'Van-accessible EV bays',
      '8-ft access aisle',
      'Step-free path to sidewalk',
    ],
    summary:
        '4 marked accessible EV parking spaces with wide aisles next to charging pedestals.',
  ),
  TransportOption(
    id: 'tx-ev-charge-midtown',
    kind: 'ev',
    name: 'Midtown Accessible EV charging hub',
    lat: 40.7552,
    lng: -73.9815,
    stepFree: true,
    verified: true,
    spaces: 6,
    apiHook: 'ev-charge-status (demo)',
    features: [
      'Wheelchair-reachable connectors',
      'Lowered payment screen',
      'Audio guidance',
      'Reserved accessible stalls',
    ],
    summary:
        'Public DC fast chargers with wheelchair-reachable cables and reserved accessible stalls.',
  ),
];

final seedAlerts = <BarrierAlert>[
  BarrierAlert(
    id: 'alert-lex-elevator',
    title: 'Elevator out — Lexington / 51 St',
    detail: 'Street-to-mezzanine elevator out of service. Use Grand Central.',
    severity: 'high',
    lat: 40.7571,
    lng: -73.9720,
    status: 'open',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    placeName: 'Lexington Ave / 51 St',
  ),
  BarrierAlert(
    id: 'alert-penn-crowd',
    title: 'Crowded 8th Ave elevator bank',
    detail: 'Long wait at Penn Station accessible entrance after 5pm.',
    severity: 'medium',
    lat: 40.7506,
    lng: -73.9935,
    status: 'open',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    placeName: 'Penn Station',
  ),
];
