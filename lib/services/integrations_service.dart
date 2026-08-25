import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/care_appointment.dart';
import '../models/integration.dart';
import '../models/place.dart';
import 'routing_service.dart';

class CreatedApiKey {
  const CreatedApiKey({required this.record, required this.token});

  final ApiKeyRecord record;
  final String token;
}

class IntegrationsService {
  IntegrationsService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    RoutingService? routing,
  }) : _db = db ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _routing = routing ?? RoutingService();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final RoutingService _routing;

  String? get uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _catalog =>
      _db.collection('integrations').doc('catalog');

  CollectionReference<Map<String, dynamic>> get _keys =>
      _db.collection('apiKeys');

  DocumentReference<Map<String, dynamic>> get _openPlaces =>
      _db.collection('openData').doc('places');

  Stream<List<IntegrationItem>> watchCatalog() {
    return _catalog.snapshots().map((snap) {
      final raw = snap.data()?['items'];
      if (raw is! List) return const <IntegrationItem>[];
      return [
        for (final e in raw)
          if (e is Map) IntegrationItem.fromMap(Map<String, dynamic>.from(e)),
      ];
    });
  }

  Stream<List<ApiKeyRecord>> watchMyKeys() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return _keys.where('uid', isEqualTo: id).snapshots().map((snap) {
      final list = snap.docs.map(ApiKeyRecord.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<OpenDataBundle?> watchOpenPlaces() {
    return _openPlaces.snapshots().map((snap) {
      if (!snap.exists) return null;
      final d = snap.data() ?? {};
      final ts = d['updatedAt'];
      return OpenDataBundle(
        kind: (d['kind'] as String?) ?? 'places',
        featureCount: (d['featureCount'] as num?)?.toInt() ?? 0,
        json: (d['json'] as String?) ?? '{}',
        updatedAt: ts is Timestamp ? ts.toDate() : null,
      );
    });
  }

  Future<void> ensureSeeded() async {
    final routingLive = await _routing.ping();
    final items = [
      IntegrationItem(
        id: 'maps',
        name: 'OpenStreetMap tiles',
        kind: 'maps',
        status: 'live',
        endpoint: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        notes: 'Ability Map and coverage maps already use OSM.',
        lastCheckedAt: DateTime.now(),
      ),
      IntegrationItem(
        id: 'routing',
        name: 'OSRM walking routes',
        kind: 'routing',
        status: routingLive ? 'live' : 'fallback',
        endpoint: RoutingService.endpoint,
        notes: routingLive
            ? 'Live geometry from the public OSRM demo. Wheelchair profile still planned.'
            : 'OSRM unreachable — straight-line fallback is on.',
        lastCheckedAt: DateTime.now(),
      ),
      const IntegrationItem(
        id: 'llm',
        name: 'Gemini via Firebase AI',
        kind: 'llm',
        status: 'live',
        endpoint: 'firebase_ai / gemini-2.0-flash',
        notes:
            'Assistant and AI tools call Gemini; local helper if the model is down.',
      ),
      const IntegrationItem(
        id: 'translation',
        name: 'Translation + plain language',
        kind: 'translation',
        status: 'live',
        endpoint: 'AiToolsService.translate / plainLanguage',
        notes:
            'Same Gemini path, with Passport language as the default target.',
      ),
      const IntegrationItem(
        id: 'payments',
        name: 'Billing sandbox',
        kind: 'payments',
        status: 'sandbox',
        endpoint: 'Firestore billingPlans / invoices',
        notes:
            'Plans and invoices are live in-app. No card numbers, no Stripe charge.',
      ),
      const IntegrationItem(
        id: 'calendar',
        name: 'Calendar (ICS)',
        kind: 'calendar',
        status: 'live',
        endpoint: 'local ICS export',
        notes:
            'Export booked visits as a .ics calendar you can paste into any calendar app.',
      ),
      const IntegrationItem(
        id: 'opendata',
        name: 'Open accessibility data',
        kind: 'opendata',
        status: 'live',
        endpoint: 'openData/places',
        notes: 'Public GeoJSON-style dump of mapped places (no personal data).',
      ),
      const IntegrationItem(
        id: 'publicapi',
        name: 'Public API keys',
        kind: 'publicapi',
        status: 'planned',
        endpoint: 'GET /v1/places (in-app explorer)',
        notes: 'Issue a key now. The hosted REST gateway is the future hook.',
      ),
    ];
    await _catalog.set({
      'items': items.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await refreshOpenPlaces();
  }

  Future<void> refreshOpenPlaces() async {
    final snap = await _db.collection('places').get();
    final features = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final p = AccessiblePlace.fromDoc(doc);
      if (p.hidden) continue;
      features.add({
        'type': 'Feature',
        'id': p.id,
        'geometry': {
          'type': 'Point',
          'coordinates': [p.lng, p.lat],
        },
        'properties': {
          'name': p.name,
          'category': p.category,
          'score': p.score,
          'verified': p.verified,
          'needs': p.needs,
          'features': p.features,
        },
      });
    }
    final bundle = {
      'type': 'FeatureCollection',
      'kind': 'places',
      'source': 'Ability Link open data',
      'features': features,
    };
    await _openPlaces.set({
      'kind': 'places',
      'featureCount': features.length,
      'json': jsonEncode(bundle),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<CreatedApiKey> createKey() async {
    final id = uid;
    if (id == null) throw StateError('Sign in to create an API key');
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    final token =
        'al_${List.generate(28, (_) => alphabet[r.nextInt(alphabet.length)]).join()}';
    final prefix = token.substring(0, 10);
    // A digest, not an encoding — base64 of the token was reversible by anyone who
    // could read this collection.
    final tokenHash = sha256.convert(utf8.encode('$id::$token')).toString();
    final ref = await _keys.add({
      'uid': id,
      'prefix': prefix,
      'tokenHash': tokenHash,
      'revoked': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return CreatedApiKey(
      record: ApiKeyRecord(
        id: ref.id,
        uid: id,
        prefix: prefix,
        tokenHash: tokenHash,
        createdAt: DateTime.now(),
      ),
      token: token,
    );
  }

  Future<void> revokeKey(String id) async {
    await _keys.doc(id).update({
      'revoked': true,
      'lastUsedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> explorePlaces(String token) async {
    final id = uid;
    if (id == null) return 'Sign in first.';
    final trimmed = token.trim();
    if (trimmed.isEmpty) return 'Paste an API key.';
    final hash = sha256.convert(utf8.encode('$id::$trimmed')).toString();
    final snap = await _keys.where('uid', isEqualTo: id).get();
    ApiKeyRecord? match;
    for (final doc in snap.docs) {
      final k = ApiKeyRecord.fromDoc(doc);
      if (!k.revoked && k.tokenHash == hash) {
        match = k;
        break;
      }
    }
    if (match == null) return 'Key not found, revoked, or not yours.';
    await _keys.doc(match.id).update({
      'lastUsedAt': FieldValue.serverTimestamp(),
    });
    final places = await _db.collection('places').limit(8).get();
    final body = {
      'ok': true,
      'endpoint': '/v1/places',
      'count': places.docs.length,
      'data': [
        for (final d in places.docs)
          {
            'id': d.id,
            'name': d.data()['name'],
            'category': d.data()['category'],
            'score': d.data()['score'],
            'verified': d.data()['verified'] == true,
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(body);
  }

  String appointmentsToIcs(List<CareAppointment> items) {
    String stamp(DateTime d) {
      final u = d.toUtc();
      String n(int v) => v.toString().padLeft(2, '0');
      return '${u.year}${n(u.month)}${n(u.day)}T${n(u.hour)}${n(u.minute)}${n(u.second)}Z';
    }

    final buf = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//Ability Link//Appointments//EN')
      ..writeln('CALSCALE:GREGORIAN');
    for (final a in items.where((e) => e.status != 'cancelled')) {
      final end = a.startAt.add(Duration(minutes: a.durationMin));
      buf
        ..writeln('BEGIN:VEVENT')
        ..writeln('UID:${a.id}@abilitylink.app')
        ..writeln('DTSTAMP:${stamp(DateTime.now())}')
        ..writeln('DTSTART:${stamp(a.startAt)}')
        ..writeln('DTEND:${stamp(end)}')
        ..writeln('SUMMARY:${_icsEscape('${a.kindLabel} · ${a.providerName}')}')
        ..writeln(
          'DESCRIPTION:${_icsEscape('${a.specialty}. ${a.modeLabel}. ${a.notes}')}',
        )
        ..writeln('END:VEVENT');
    }
    buf.writeln('END:VCALENDAR');
    return buf.toString();
  }

  String _icsEscape(String raw) {
    return raw
        .replaceAll('\\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\n', r'\n');
  }
}
