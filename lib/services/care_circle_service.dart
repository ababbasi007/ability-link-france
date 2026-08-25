import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/care_circle.dart';
import '../models/care_shared_route.dart';
import 'billing_service.dart';
import 'location_service.dart';
import 'notification_service.dart';

class CareCircleService {
  CareCircleService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _col(String name) {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Sign in required');
    }
    return _db.collection('users').doc(uid).collection(name);
  }

  CollectionReference<Map<String, dynamic>> get _members => _col('careMembers');
  CollectionReference<Map<String, dynamic>> get _tasks => _col('careTasks');
  CollectionReference<Map<String, dynamic>> get _notes => _col('careNotes');
  CollectionReference<Map<String, dynamic>> get _history => _col('careHistory');
  CollectionReference<Map<String, dynamic>> get _messages =>
      _col('careMessages');
  CollectionReference<Map<String, dynamic>> get _hires => _col('careHires');
  CollectionReference<Map<String, dynamic>> get _careLocations =>
      _col('careLocations');
  CollectionReference<Map<String, dynamic>> get _sharedRoutes =>
      _col('careSharedRoutes');

  Stream<AppLatLng?> watchSelfLocation() {
    if (_uid == null) return Stream.value(null);
    return _careLocations.doc('self').snapshots().map((snap) {
      final d = snap.data() ?? {};
      final lat = (d['lat'] as num?)?.toDouble();
      final lng = (d['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return AppLatLng(lat, lng);
    });
  }

  Stream<DateTime?> watchSelfLocationUpdatedAt() {
    if (_uid == null) return Stream.value(null);
    return _careLocations.doc('self').snapshots().map((snap) {
      final d = snap.data() ?? {};
      final ts = d['updatedAt'];
      if (ts is Timestamp) return ts.toDate();
      return null;
    });
  }

  Future<void> updateSelfLocation({
    required double lat,
    required double lng,
  }) async {
    if (_uid == null) throw StateError('Sign in required');
    await _careLocations.doc('self').set({
      'lat': lat,
      'lng': lng,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<CareSharedRoute>> watchSharedRoutes() {
    if (_uid == null) return Stream.value(const []);
    return _sharedRoutes
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CareSharedRoute.fromDoc).toList());
  }

  Future<String> shareRoute(Map<String, dynamic> payload) async {
    if (_uid == null) throw StateError('Sign in required');
    final ref = _sharedRoutes.doc();
    await ref.set(payload);
    await _history.doc().set({
      'title': 'Shared route: ${payload['destinationName'] ?? 'Trip'}',
      'detail': payload['title'] ?? '',
      'kind': 'route',
      'relatedId': ref.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> deleteSharedRoute(String id) async {
    if (_uid == null) throw StateError('Sign in required');
    await _sharedRoutes.doc(id).delete();
  }

  Stream<List<CareMember>> watchMembers() {
    if (_uid == null) return Stream.value(const []);
    return _members.snapshots().map(
      (snap) => snap.docs.map(CareMember.fromDoc).toList(),
    );
  }

  Stream<List<CareTask>> watchTasks() {
    if (_uid == null) return Stream.value(const []);
    return _tasks.snapshots().map((snap) {
      final list = snap.docs.map(CareTask.fromDoc).toList();
      list.sort((a, b) => a.timeLabel.compareTo(b.timeLabel));
      return list;
    });
  }

  Stream<List<CareNote>> watchNotes() {
    if (_uid == null) return Stream.value(const []);
    return _notes
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CareNote.fromDoc).toList());
  }

  Stream<List<CareHistoryEvent>> watchHistory() {
    if (_uid == null) return Stream.value(const []);
    return _history
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CareHistoryEvent.fromDoc).toList());
  }

  Stream<List<CareMessage>> watchMessages() {
    if (_uid == null) return Stream.value(const []);
    return _messages
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(CareMessage.fromDoc).toList());
  }

  Stream<List<CareHireRequest>> watchHires() {
    if (_uid == null) return Stream.value(const []);
    return _hires
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CareHireRequest.fromDoc).toList());
  }

  Future<void> ensureSeeded() async {
    if (_uid == null) return;

    final membersSnap = await _members.limit(1).get();
    if (membersSnap.docs.isEmpty) {
      final batch = _db.batch();
      for (final m in seedMembers) {
        batch.set(_members.doc(m.id), m.toMap());
      }
      for (final t in seedTasks) {
        batch.set(_tasks.doc(t.id), {
          'title': t.title,
          'personName': t.personName,
          'timeLabel': t.timeLabel,
          'kind': t.kind,
          'status': t.status,
          'notes': t.notes,
          'createdAt': FieldValue.serverTimestamp(),
          if (t.isDone) 'completedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }

    final notesSnap = await _notes.limit(1).get();
    if (notesSnap.docs.isEmpty) {
      final batch = _db.batch();
      for (final n in seedNotes) {
        batch.set(_notes.doc(n.id), {
          'title': n.title,
          'body': n.body,
          'author': n.author,
          'personName': n.personName,
          'kind': n.kind,
          'createdAt': Timestamp.fromDate(n.createdAt),
        });
      }
      await batch.commit();
    }

    final histSnap = await _history.limit(1).get();
    if (histSnap.docs.isEmpty) {
      final batch = _db.batch();
      for (final h in seedHistory) {
        batch.set(_history.doc(h.id), {
          'title': h.title,
          'detail': h.detail,
          'kind': h.kind,
          'relatedId': h.relatedId,
          'createdAt': Timestamp.fromDate(h.createdAt),
        });
      }
      await batch.commit();
    }

    final msgSnap = await _messages.limit(1).get();
    if (msgSnap.docs.isEmpty) {
      await _messages.doc('welcome').set({
        'author': 'Care Circle',
        'body':
            'Welcome to your family care chat. Share updates, meds, and visit notes here.',
        'uid': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> addMember({
    required String name,
    required String relation,
    required List<String> permissions,
    String phone = '',
    String role = 'family',
    String providerId = '',
    String bio = '',
    bool availableNow = false,
    bool verified = false,
    int colorValue = 0xFF14B8A6,
  }) async {
    await _members.doc().set({
      'name': name.trim(),
      'relation': relation.trim(),
      'permissions': permissions,
      'colorValue': colorValue,
      'phone': phone.trim(),
      'role': role,
      'providerId': providerId,
      'bio': bio.trim(),
      'availableNow': availableNow,
      'verified': verified,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await logHistory(
      title: 'Member added',
      detail: '$name joined the care circle as $relation',
      kind: 'message',
    );
  }

  Future<void> updatePermissions(String id, List<String> permissions) async {
    await _members.doc(id).update({'permissions': permissions});
  }

  Future<void> removeMember(String id) async {
    await _members.doc(id).delete();
  }

  Future<void> addTask({
    required String title,
    required String personName,
    required String timeLabel,
    required String kind,
    String notes = '',
  }) async {
    final ref = _tasks.doc();
    await ref.set({
      'title': title.trim(),
      'personName': personName.trim(),
      'timeLabel': timeLabel.trim(),
      'kind': kind,
      'status': 'pending',
      'notes': notes.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await logHistory(
      title: 'Task scheduled',
      detail:
          '$title · $timeLabel${personName.isEmpty ? '' : ' · $personName'}',
      kind: kind == 'appointment' ? 'appointment' : 'task',
      relatedId: ref.id,
    );
    final uid = _uid;
    if (uid != null) {
      await NotificationService(db: _db, auth: _auth).notify(
        uid: uid,
        type: 'caregiver',
        title: 'Care task scheduled',
        body: '$title · $timeLabel',
        relatedId: ref.id,
      );
    }
  }

  Future<void> toggleTask(CareTask task) async {
    final markingDone = !task.isDone;
    await _tasks.doc(task.id).update({
      'status': markingDone ? 'done' : 'pending',
      'completedAt': markingDone
          ? FieldValue.serverTimestamp()
          : FieldValue.delete(),
    });
    if (markingDone) {
      await logHistory(
        title: 'Completed: ${task.title}',
        detail: task.personName.isEmpty
            ? task.timeLabel
            : '${task.personName} · ${task.timeLabel}',
        kind: task.kind == 'meds' ? 'meds' : 'task',
        relatedId: task.id,
      );
    }
  }

  Future<void> deleteTask(String id) async {
    await _tasks.doc(id).delete();
  }

  Future<void> addNote({
    required String title,
    required String body,
    String author = 'You',
    String personName = '',
    String kind = 'general',
  }) async {
    final ref = _notes.doc();
    await ref.set({
      'title': title.trim(),
      'body': body.trim(),
      'author': author.trim().isEmpty ? 'You' : author.trim(),
      'personName': personName.trim(),
      'kind': kind,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await logHistory(
      title: 'Note: ${title.trim()}',
      detail: body.trim().length > 120
          ? '${body.trim().substring(0, 117)}…'
          : body.trim(),
      kind: 'note',
      relatedId: ref.id,
    );
  }

  Future<void> deleteNote(String id) async {
    await _notes.doc(id).delete();
  }

  Future<void> logHistory({
    required String title,
    required String detail,
    required String kind,
    String relatedId = '',
  }) async {
    if (_uid == null) return;
    await _history.doc().set({
      'title': title,
      'detail': detail,
      'kind': kind,
      'relatedId': relatedId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendMessage({
    required String body,
    String author = 'You',
  }) async {
    final text = body.trim();
    if (text.isEmpty) return;
    final uid = _uid ?? '';
    await _messages.doc().set({
      'author': author,
      'body': text,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (uid.isNotEmpty && author != 'You') {
      await NotificationService(db: _db, auth: _auth).notify(
        uid: uid,
        type: 'message',
        title: 'Care circle message',
        body: text,
        relatedId: 'care-chat',
      );
    }
  }

  Future<String> submitHireRequest({
    required String providerId,
    required String providerName,
    required String service,
    required String scheduleLabel,
    required String notes,
    String phone = '',
    String ownerUid = '',
    bool payNow = true,
    int amountCents = 2500,
  }) async {
    final ref = _hires.doc();
    var paymentStatus = 'unpaid';
    var invoiceId = '';
    if (payNow) {
      invoiceId = await BillingService(db: _db, auth: _auth).payService(
        type: 'caregiver',
        description: 'Caregiver hire · $providerName',
        amountCents: amountCents,
        relatedId: ref.id,
      );
      paymentStatus = 'paid';
    }
    await ref.set({
      'providerId': providerId,
      'providerName': providerName,
      'service': service,
      'scheduleLabel': scheduleLabel,
      'notes': notes,
      'phone': phone,
      'ownerUid': ownerUid,
      'status': 'requested',
      'paymentStatus': paymentStatus,
      'invoiceId': invoiceId,
      'amountCents': amountCents,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await logHistory(
      title: 'Hire requested: $providerName',
      detail: '$service · $scheduleLabel',
      kind: 'hire',
      relatedId: ref.id,
    );
    final notesSvc = NotificationService(db: _db, auth: _auth);
    final uid = _uid;
    if (uid != null) {
      await notesSvc.notify(
        uid: uid,
        type: 'caregiver',
        title: 'Caregiver hire requested',
        body: '$providerName · $service',
        relatedId: ref.id,
      );
    }
    if (ownerUid.isNotEmpty && ownerUid != uid) {
      await notesSvc.notify(
        uid: ownerUid,
        type: 'caregiver',
        title: 'New hire request',
        body: '$service · $scheduleLabel',
        relatedId: ref.id,
      );
    }
    return ref.id;
  }

  Future<void> updateHireStatus(String id, String status) async {
    await _hires.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await logHistory(
      title: 'Hire $status',
      detail: 'Request $id marked $status',
      kind: 'hire',
      relatedId: id,
    );
    final uid = _uid;
    if (uid != null) {
      await NotificationService(db: _db, auth: _auth).notify(
        uid: uid,
        type: 'caregiver',
        title: 'Hire $status',
        body: 'Your caregiver request was marked $status.',
        relatedId: id,
      );
    }
  }
}

final seedMembers = <CareMember>[
  CareMember(
    id: 'm-abdul',
    name: 'Abdul Rehman',
    relation: 'Father',
    permissions: ['viewPassport', 'viewLocation', 'manageTasks', 'meds'],
    colorValue: 0xFF94A3B8,
    phone: '+1 212 555 0142',
  ),
  CareMember(
    id: 'm-sara',
    name: 'Sara Khan',
    relation: 'Sister',
    permissions: ['viewPassport', 'manageTasks'],
    colorValue: 0xFFF472B6,
    phone: '+1 212 555 0198',
  ),
  CareMember(
    id: 'm-ali',
    name: 'Ali Khan',
    relation: 'Son',
    permissions: ['viewLocation', 'meds'],
    colorValue: 0xFF60A5FA,
  ),
  CareMember(
    id: 'm-priya',
    name: 'Priya Nair',
    relation: 'Care coordinator',
    permissions: ['manageTasks', 'meds', 'viewPassport'],
    colorValue: 0xFF14B8A6,
    phone: '+1 917 555 0104',
    role: 'professional',
    providerId: 'care-priya-nair',
    bio:
        'RN care coordinator — schedules, meds, and family briefings. Verified on Ability Link.',
    availableNow: true,
    verified: true,
  ),
];

final seedTasks = <CareTask>[
  CareTask(
    id: 't-bp',
    title: 'Blood Pressure Medicine',
    personName: 'Abdul Rehman',
    timeLabel: '08:00 AM',
    kind: 'meds',
    status: 'done',
  ),
  CareTask(
    id: 't-pt',
    title: 'Physiotherapy Exercise',
    personName: 'Sara Khan',
    timeLabel: '11:00 AM',
    kind: 'task',
    status: 'pending',
  ),
  CareTask(
    id: 't-doc',
    title: 'Doctor Appointment',
    personName: 'Ali Khan',
    timeLabel: '04:00 PM',
    kind: 'appointment',
    status: 'pending',
  ),
  CareTask(
    id: 't-pm',
    title: 'Evening Medication',
    personName: 'Abdul Rehman',
    timeLabel: '08:00 PM',
    kind: 'meds',
    status: 'pending',
  ),
  CareTask(
    id: 't-pa',
    title: 'Personal assistance visit',
    personName: 'Priya Nair',
    timeLabel: '02:00 PM',
    kind: 'assistance',
    status: 'pending',
    notes: 'Transfer support and meal prep',
  ),
];

final seedNotes = <CareNote>[
  CareNote(
    id: 'n-bp',
    title: 'Morning BP check',
    body:
        'Abdul: 128/78, resting. Took morning meds with food. No dizziness reported.',
    author: 'Priya Nair',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    personName: 'Abdul Rehman',
    kind: 'meds',
  ),
  CareNote(
    id: 'n-visit',
    title: 'Home visit summary',
    body:
        'Helped with transfer to shower chair. Kitchen accessible path clear. Family briefed on evening routine.',
    author: 'You',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    personName: 'Abdul Rehman',
    kind: 'visit',
  ),
];

final seedHistory = <CareHistoryEvent>[
  CareHistoryEvent(
    id: 'h1',
    title: 'Completed: Blood Pressure Medicine',
    detail: 'Abdul Rehman · 08:00 AM',
    kind: 'meds',
    createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    relatedId: 't-bp',
  ),
  CareHistoryEvent(
    id: 'h2',
    title: 'Note: Home visit summary',
    detail: 'Transfer support and evening routine briefing',
    kind: 'note',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    relatedId: 'n-visit',
  ),
  CareHistoryEvent(
    id: 'h3',
    title: 'Care circle ready',
    detail: 'Family members and professional caregiver linked',
    kind: 'message',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
];
