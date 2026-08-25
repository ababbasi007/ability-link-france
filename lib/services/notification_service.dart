import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_notification.dart';
import 'background_task.dart';
import 'location_service.dart';
import 'places_service.dart';
import 'push_service.dart';

class NotificationService {
  NotificationService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    PlacesService? places,
  }) : _db = db ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _places = places ?? PlacesService();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final PlacesService _places;

  String? get uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _notes =>
      _db.collection('notifications');

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final id = uid;
    if (id == null) return null;
    return _db.collection('users').doc(id);
  }

  CollectionReference<Map<String, dynamic>>? get _saved {
    final id = uid;
    if (id == null) return null;
    return _db.collection('users').doc(id).collection('savedSearches');
  }

  Stream<List<AppNotification>> watchMine() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return _notes.where('uid', isEqualTo: id).snapshots().map((snap) {
      final list = snap.docs.map(AppNotification.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<int> watchUnreadCount() {
    return watchMine().map((list) => list.where((n) => !n.read).length);
  }

  Stream<NotificationPrefs> watchPrefs() {
    final doc = _userDoc;
    if (doc == null) return Stream.value(const NotificationPrefs());
    return doc.snapshots().map((snap) {
      final data = snap.data()?['notificationPrefs'];
      return NotificationPrefs.fromMap(
        data is Map ? Map<String, dynamic>.from(data) : null,
      );
    });
  }

  Stream<List<SavedSearch>> watchSavedSearches() {
    final col = _saved;
    if (col == null) return Stream.value(const []);
    return col.snapshots().map((snap) {
      final list = snap.docs.map(SavedSearch.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> savePrefs(NotificationPrefs prefs) async {
    final doc = _userDoc;
    if (doc == null) throw StateError('Sign in required');
    await doc.set({
      'notificationPrefs': prefs.toMap(),
    }, SetOptions(merge: true));
    runInBackground(PushService.instance.sync(prefs: prefs), 'push token sync');
  }

  Future<void> markRead(String id) async {
    await _notes.doc(id).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllRead(List<AppNotification> items) async {
    final batch = _db.batch();
    for (final n in items.where((e) => !e.read)) {
      batch.update(_notes.doc(n.id), {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> notify({
    required String uid,
    required String type,
    required String title,
    required String body,
    String relatedId = '',
    NotificationPrefs? prefs,
  }) async {
    if (uid.isEmpty) return;
    final effective = prefs ?? await _prefsFor(uid);
    if (!effective.allows(type)) return;
    final channels = <String>[
      if (effective.inApp) 'inApp',
      if (effective.push) 'push',
      if (effective.email) 'email',
      if (effective.sms) 'sms',
    ];
    if (channels.isEmpty) return;
    await _notes.doc().set({
      'uid': uid,
      'createdBy': _auth.currentUser?.uid ?? uid,
      'type': type,
      'title': title,
      'body': body,
      'relatedId': relatedId,
      'read': false,
      'channels': channels,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<NotificationPrefs> _prefsFor(String userId) async {
    try {
      final snap = await _db.collection('users').doc(userId).get();
      final data = snap.data()?['notificationPrefs'];
      return NotificationPrefs.fromMap(
        data is Map ? Map<String, dynamic>.from(data) : null,
      );
    } catch (_) {
      return const NotificationPrefs();
    }
  }

  Future<void> notifyBooking({
    required String patientUid,
    required String providerName,
    required String appointmentId,
    String ownerUid = '',
    String kind = 'visit',
  }) async {
    final label = switch (kind) {
      'rehab' => 'Rehab session',
      'telehealth' => 'Telehealth visit',
      'assistance' => 'Assistance booking',
      'travel' => 'Travel booking',
      _ => 'Appointment',
    };
    await notify(
      uid: patientUid,
      type: 'booking',
      title: '$label confirmed',
      body: 'Your booking with $providerName is confirmed.',
      relatedId: appointmentId,
    );
    if (ownerUid.isNotEmpty && ownerUid != patientUid) {
      await notify(
        uid: ownerUid,
        type: 'booking',
        title: 'New booking',
        body: 'Someone booked $providerName.',
        relatedId: appointmentId,
      );
    }
  }

  Future<void> notifyPayment({
    required String uid,
    required String description,
    required int amountCents,
    required String invoiceId,
    String title = 'Payment received',
  }) async {
    await notify(
      uid: uid,
      type: 'payment',
      title: title,
      body:
          '$description · \$${(amountCents / 100).toStringAsFixed(2)} (sandbox)',
      relatedId: invoiceId,
    );
  }

  Future<void> notifyMessage({
    required String uid,
    required String title,
    required String body,
    String relatedId = '',
  }) async {
    if (uid == this.uid) return;
    await notify(
      uid: uid,
      type: 'message',
      title: title,
      body: body,
      relatedId: relatedId,
    );
  }

  Future<Set<String>> _relatedIds(String userId) async {
    final existing = await _notes.where('uid', isEqualTo: userId).get();
    return existing.docs
        .map((d) => (d.data()['relatedId'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  String _dayKey([DateTime? at]) {
    final d = at ?? DateTime.now();
    return '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
  }

  DateTime? _clockToday(String label, {int? hour, int? minute}) {
    var h = hour;
    var m = minute;
    if (h == null || m == null) {
      final re = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false);
      final match = re.firstMatch(label);
      if (match == null) return null;
      h = int.parse(match.group(1)!);
      m = int.parse(match.group(2)!);
      final ampm = match.group(3)?.toUpperCase();
      if (ampm == 'PM' && h < 12) h += 12;
      if (ampm == 'AM' && h == 12) h = 0;
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, m);
  }

  bool _isDueSoon(DateTime at, {int pastMin = 30, int futureMin = 120}) {
    final now = DateTime.now();
    return at.isAfter(now.subtract(Duration(minutes: pastMin))) &&
        at.isBefore(now.add(Duration(minutes: futureMin)));
  }

  Future<void> syncDueReminders() async {
    final id = uid;
    if (id == null) return;
    final prefs = await _prefsFor(id);
    final seen = await _relatedIds(id);
    final today = _dayKey();

    await _syncTimedBookings(
      uid: id,
      prefs: prefs,
      seen: seen,
      today: today,
      collection: 'appointments',
      typeFor: (d) => switch ((d['kind'] as String?) ?? 'telehealth') {
        'rehab' => 'rehab',
        'telehealth' => 'telehealth',
        _ => 'appointment',
      },
      titleFor: (d) => switch ((d['kind'] as String?) ?? 'telehealth') {
        'rehab' => 'Rehab session soon',
        'telehealth' => 'Telehealth reminder',
        _ => 'Appointment reminder',
      },
      nameFor: (d) => (d['providerName'] as String?) ?? 'Your visit',
    );
    await _syncTimedBookings(
      uid: id,
      prefs: prefs,
      seen: seen,
      today: today,
      collection: 'assistanceBookings',
      typeFor: (_) => 'booking',
      titleFor: (_) => 'Assistance reminder',
      nameFor: (d) => (d['providerName'] as String?) ?? 'Your assistant',
    );
    await _syncTimedBookings(
      uid: id,
      prefs: prefs,
      seen: seen,
      today: today,
      collection: 'travelBookings',
      typeFor: (_) => 'booking',
      titleFor: (_) => 'Travel reminder',
      nameFor: (d) => (d['destinationName'] as String?) ?? 'Your trip',
    );

    await _syncClockReminders(
      uid: id,
      prefs: prefs,
      seen: seen,
      today: today,
      col: _db.collection('users').doc(id).collection('medReminders'),
      type: 'telehealth',
      titlePrefix: 'Medication',
    );
    await _syncClockReminders(
      uid: id,
      prefs: prefs,
      seen: seen,
      today: today,
      col: _db.collection('users').doc(id).collection('rehabReminders'),
      typeFor: (kind) => kind == 'exercise' ? 'exercise' : 'rehab',
    );
    await _syncClockReminders(
      uid: id,
      prefs: prefs,
      seen: seen,
      today: today,
      col: _db.collection('users').doc(id).collection('careTasks'),
      type: 'caregiver',
      titlePrefix: 'Care task',
      whenField: 'timeLabel',
      skipDone: true,
    );

    final apps = await _db
        .collection('benefitApplications')
        .where('uid', isEqualTo: id)
        .get();
    for (final doc in apps.docs) {
      final d = doc.data();
      final ts = d['remindAt'];
      if (ts is! Timestamp) continue;
      if (ts.toDate().isAfter(DateTime.now())) continue;
      final related = 'benefit_due_${doc.id}';
      if (seen.contains(related)) continue;
      await notify(
        uid: id,
        type: 'benefit_reminder',
        title: 'Benefit follow-up due',
        body: (d['schemeName'] as String?) ?? 'Check your application',
        relatedId: related,
        prefs: prefs,
      );
      seen.add(related);
    }

    await checkNearbyAlerts(prefs: prefs, seen: seen);
    await checkSavedSearchHits();
  }

  Future<void> _syncTimedBookings({
    required String uid,
    required NotificationPrefs prefs,
    required Set<String> seen,
    required String today,
    required String collection,
    required String Function(Map<String, dynamic> d) typeFor,
    required String Function(Map<String, dynamic> d) titleFor,
    required String Function(Map<String, dynamic> d) nameFor,
  }) async {
    final snap = await _db
        .collection(collection)
        .where('uid', isEqualTo: uid)
        .get();
    for (final doc in snap.docs) {
      final d = doc.data();
      if ((d['status'] as String?) != 'booked') continue;
      final ts = d['startAt'];
      if (ts is! Timestamp) continue;
      final start = ts.toDate();
      if (!_isDueSoon(start)) continue;
      final related = 'due_${doc.id}_$today';
      if (seen.contains(related)) continue;
      await notify(
        uid: uid,
        type: typeFor(d),
        title: titleFor(d),
        body: '${nameFor(d)} starts ${_fmtWhen(start)}.',
        relatedId: related,
        prefs: prefs,
      );
      seen.add(related);
    }
  }

  Future<void> _syncClockReminders({
    required String uid,
    required NotificationPrefs prefs,
    required Set<String> seen,
    required String today,
    required CollectionReference<Map<String, dynamic>> col,
    String type = 'reminder',
    String titlePrefix = '',
    String whenField = 'whenLabel',
    bool skipDone = false,
    String Function(String kind)? typeFor,
  }) async {
    final snap = await col.get();
    for (final doc in snap.docs) {
      final d = doc.data();
      if (skipDone && (d['status'] as String?) == 'done') continue;
      final hour = (d['hour'] as num?)?.toInt();
      final minute = (d['minute'] as num?)?.toInt();
      final when = (d[whenField] as String?) ?? '';
      final at = _clockToday(when, hour: hour, minute: minute);
      if (at == null || !_isDueSoon(at, pastMin: 45, futureMin: 20)) continue;
      final related = 'clock_${doc.id}_$today';
      if (seen.contains(related)) continue;
      final kind = (d['kind'] as String?) ?? '';
      await notify(
        uid: uid,
        type: typeFor?.call(kind) ?? type,
        title: (d['title'] as String?)?.trim().isNotEmpty == true
            ? d['title'] as String
            : (titlePrefix.isEmpty ? 'Reminder' : titlePrefix),
        body: when.isEmpty ? 'Due now' : when,
        relatedId: related,
        prefs: prefs,
      );
      seen.add(related);
    }
  }

  String _fmtWhen(DateTime d) {
    final l = d.toLocal();
    final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final m = l.minute.toString().padLeft(2, '0');
    final am = l.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $am';
  }

  Future<void> checkNearbyAlerts({
    NotificationPrefs? prefs,
    Set<String>? seen,
  }) async {
    final id = uid;
    if (id == null) return;
    final effective = prefs ?? await _prefsFor(id);
    if (!effective.allows('nearby')) return;
    final known = seen ?? await _relatedIds(id);
    final origin = LocationService.instance.current;
    final places = await _places.watchPlaces().first;
    final nearby =
        places.where((p) {
          if (p.hidden) return false;
          return p.distanceKm(origin.lat, origin.lng) <= 1.5 && p.score >= 70;
        }).toList()..sort(
          (a, b) => a
              .distanceKm(origin.lat, origin.lng)
              .compareTo(b.distanceKm(origin.lat, origin.lng)),
        );
    for (final p in nearby.take(2)) {
      final related = 'nearby_${p.id}_${_dayKey()}';
      if (known.contains(related)) continue;
      await notify(
        uid: id,
        type: 'nearby',
        title: 'Accessible place nearby',
        body:
            '${p.name} · ${p.distanceLabel(origin.lat, origin.lng)} · score ${p.score}',
        relatedId: related,
        prefs: effective,
      );
      known.add(related);
    }
  }

  Future<void> notifyBarrier({
    required String title,
    required String detail,
    required String alertId,
  }) async {
    final id = uid;
    if (id == null) return;
    await notify(
      uid: id,
      type: 'barrier',
      title: 'Barrier reported',
      body: '$title. $detail',
      relatedId: alertId,
    );
  }

  Future<void> saveSearch({required String query, required String need}) async {
    final col = _saved;
    if (col == null) throw StateError('Sign in to save a search');
    final ref = await col.add({
      'query': query.trim(),
      'need': need,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await notify(
      uid: uid!,
      type: 'saved_search',
      title: 'Search saved',
      body: 'We will alert you when new places match "${query.trim()}".',
      relatedId: ref.id,
    );
    await checkSavedSearchHits();
  }

  Future<void> deleteSavedSearch(String id) async {
    await _saved?.doc(id).delete();
  }

  Future<void> checkSavedSearchHits() async {
    final id = uid;
    final col = _saved;
    if (id == null || col == null) return;
    final prefs = await _prefsFor(id);
    if (!prefs.allows('saved_search')) return;
    final searches = await col.get();
    if (searches.docs.isEmpty) return;
    final places = await _places.watchPlaces().first;
    final today = DateTime.now().toIso8601String().split('T').first;
    for (final doc in searches.docs) {
      final s = SavedSearch.fromDoc(doc);
      final matches = _places.search(places, query: s.query, need: s.need);
      if (matches.isEmpty) continue;
      final related = 'hit_${s.id}_$today';
      final existing = await _notes.where('uid', isEqualTo: id).get();
      if (existing.docs.any((d) => d.data()['relatedId'] == related)) {
        continue;
      }
      await notify(
        uid: id,
        type: 'saved_search',
        title: 'New match for a saved search',
        body:
            '${matches.length} place${matches.length == 1 ? '' : 's'} match "${s.label}".',
        relatedId: related,
        prefs: prefs,
      );
    }
  }

  Future<void> ensureWelcome() async {
    final id = uid;
    if (id == null) return;
    final existing = await _notes.where('uid', isEqualTo: id).limit(1).get();
    if (existing.docs.isNotEmpty) return;
    await notify(
      uid: id,
      type: 'general',
      title: 'Notifications are on',
      body:
          'Bookings, payments, reminders, messages, benefits, and nearby alerts land here. In-app and push are live. Email and SMS prefs are stored for later gateways.',
      relatedId: 'welcome',
    );
  }
}
