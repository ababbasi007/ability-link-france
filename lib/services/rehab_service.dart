import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/rehab.dart';
import '../models/user_profile.dart';
import 'notification_service.dart';

class RehabService {
  RehabService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _exercises =>
      _db.collection('rehabExercises');
  CollectionReference<Map<String, dynamic>> get _programs =>
      _db.collection('rehabPrograms');

  CollectionReference<Map<String, dynamic>>? _userCol(String name) {
    final id = uid;
    if (id == null) return null;
    return _db.collection('users').doc(id).collection(name);
  }

  Stream<List<RehabExercise>> watchExercises({String category = 'all'}) {
    return _exercises.snapshots().map((snap) {
      var list = snap.docs.map(RehabExercise.fromDoc).toList();
      if (category != 'all') {
        list = list.where((e) => e.category == category).toList();
      }
      return list;
    });
  }

  Future<RehabExercise?> getExercise(String id) async {
    final doc = await _exercises.doc(id).get();
    if (!doc.exists) return null;
    return RehabExercise.fromDoc(doc);
  }

  Stream<List<RehabProgram>> watchPrograms() {
    return _programs.snapshots().map(
      (s) => s.docs.map(RehabProgram.fromDoc).toList(),
    );
  }

  Stream<Map<String, RehabPlanItem>> watchPlan() {
    final col = _userCol('rehabPlan');
    if (col == null) return Stream.value({});
    return col.snapshots().map((snap) {
      return {
        for (final d in snap.docs) d.id: RehabPlanItem.fromMap(d.id, d.data()),
      };
    });
  }

  Stream<List<RehabGoal>> watchGoals() {
    final col = _userCol('rehabGoals');
    if (col == null) return Stream.value(const []);
    return col.snapshots().map((s) => s.docs.map(RehabGoal.fromDoc).toList());
  }

  Stream<List<RehabHealthEntry>> watchHealth() {
    final col = _userCol('rehabHealth');
    if (col == null) return Stream.value(const []);
    return col.snapshots().map((snap) {
      final list = snap.docs.map(RehabHealthEntry.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<RehabNote>> watchNotes() {
    final col = _userCol('rehabNotes');
    if (col == null) return Stream.value(const []);
    return col.snapshots().map((snap) {
      final list = snap.docs.map(RehabNote.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<RehabReminder>> watchReminders() {
    final col = _userCol('rehabReminders');
    if (col == null) return Stream.value(const []);
    return col.snapshots().map(
      (s) => s.docs.map(RehabReminder.fromDoc).toList(),
    );
  }

  Stream<List<RehabLog>> watchLogs() {
    final col = _userCol('rehabLogs');
    if (col == null) return Stream.value(const []);
    return col.snapshots().map((snap) {
      final list = snap.docs.map(RehabLog.fromDoc).toList();
      list.sort((a, b) => a.day.compareTo(b.day));
      return list;
    });
  }

  DocumentReference<Map<String, dynamic>> _thread(String threadId) =>
      _db.collection('sessionChats').doc(threadId);

  /// Threads are readable only by the uids listed on the thread doc, so a
  /// participant has to be registered before messages can be read or sent.
  Future<void> ensureChatThread(
    String threadId, {
    String appointmentId = '',
  }) async {
    final id = uid;
    if (id == null) return;
    final ref = _thread(threadId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participants': [id],
        'appointmentId': appointmentId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    final current = (snap.data()?['participants'] as List?) ?? const [];
    if (current.contains(id)) return;
    await ref.update({
      'participants': FieldValue.arrayUnion([id]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<SessionChatMessage>> watchChat(String threadId) {
    return _db
        .collection('sessionChats')
        .doc(threadId)
        .collection('messages')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(SessionChatMessage.fromDoc).toList();
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return list;
        });
  }

  Future<void> sendChat({
    required String threadId,
    required String body,
    String author = 'You',
    String appointmentId = '',
  }) async {
    final id = uid;
    if (id == null) throw StateError('Sign in to chat');
    await ensureChatThread(threadId, appointmentId: appointmentId);
    await _db
        .collection('sessionChats')
        .doc(threadId)
        .collection('messages')
        .add({
          'uid': id,
          'author': author,
          'body': body.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
    var other = '';
    final recent = await _db
        .collection('sessionChats')
        .doc(threadId)
        .collection('messages')
        .get();
    for (final d in recent.docs) {
      final u = (d.data()['uid'] as String?) ?? '';
      if (u.isNotEmpty && u != id) {
        other = u;
        break;
      }
    }
    if (other.isEmpty && threadId.startsWith('session-')) {
      final appt = await _db
          .collection('appointments')
          .doc(threadId.substring('session-'.length))
          .get();
      final patient = (appt.data()?['uid'] as String?) ?? '';
      if (patient.isNotEmpty && patient != id) other = patient;
    }
    if (other.isNotEmpty) {
      await NotificationService(db: _db, auth: _auth).notifyMessage(
        uid: other,
        title: 'New session message',
        body: body.trim(),
        relatedId: threadId,
      );
    }
  }

  Future<void> markPlanStatus({
    required String exerciseId,
    required String status,
    int completedSets = 0,
  }) async {
    final col = _userCol('rehabPlan');
    if (col == null) throw StateError('Sign in required');
    await col.doc(exerciseId).set({
      'status': status,
      'completedSets': completedSets,
      'exerciseId': exerciseId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _refreshTodayLog();
  }

  Future<void> _refreshTodayLog() async {
    final col = _userCol('rehabPlan');
    final logs = _userCol('rehabLogs');
    if (col == null || logs == null) return;
    final snap = await col.get();
    if (snap.docs.isEmpty) return;
    final done = snap.docs.where((d) => d.data()['status'] == 'done').length;
    final pct = ((done / snap.docs.length) * 100).round();
    final now = DateTime.now();
    final key =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await logs.doc(key).set({
      'day': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
      'percent': pct,
    });
  }

  Future<void> addGoal({required String title, required String target}) async {
    final col = _userCol('rehabGoals');
    if (col == null) throw StateError('Sign in required');
    await col.add({
      'title': title.trim(),
      'target': target.trim(),
      'progress': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setGoalProgress(String id, int progress) async {
    final col = _userCol('rehabGoals');
    if (col == null) return;
    await col.doc(id).update({'progress': progress.clamp(0, 100)});
  }

  Future<void> addHealth({
    required int pain,
    required int energy,
    required int mobility,
    String note = '',
  }) async {
    final col = _userCol('rehabHealth');
    if (col == null) throw StateError('Sign in required');
    await col.add({
      'pain': pain,
      'energy': energy,
      'mobility': mobility,
      'note': note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addNote({
    required String author,
    required String body,
    String appointmentId = '',
  }) async {
    final col = _userCol('rehabNotes');
    if (col == null) throw StateError('Sign in required');
    await col.add({
      'author': author,
      'body': body.trim(),
      'appointmentId': appointmentId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addReminder({
    required String title,
    required String whenLabel,
    String kind = 'exercise',
    int? hour,
    int? minute,
  }) async {
    final col = _userCol('rehabReminders');
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

  Future<void> assignProgram(RehabProgram program) async {
    final col = _userCol('rehabPlan');
    if (col == null) throw StateError('Sign in required');
    final batch = _db.batch();
    for (var i = 0; i < program.exerciseIds.length; i++) {
      final id = program.exerciseIds[i];
      batch.set(col.doc(id), {
        'exerciseId': id,
        'status': i == 0 ? 'inProgress' : 'pending',
        'completedSets': 0,
      });
    }
    await batch.commit();
  }

  List<RehabExercise> personalized(
    List<RehabExercise> all,
    UserProfile? profile,
  ) {
    final needs = [
      ...?profile?.accessibilityProfiles.map((e) => e.toLowerCase()),
      profile?.mobilityAid.toLowerCase() ?? '',
    ].where((e) => e.isNotEmpty).toList();
    if (needs.isEmpty) return all.take(6).toList();
    int score(RehabExercise e) {
      var s = 0;
      for (final n in needs) {
        if (e.tags.any((t) => n.contains(t) || t.contains(n))) s += 3;
        if (n.contains('speech') && e.discipline == 'speech') s += 5;
        if (n.contains('wheelchair') && e.tags.contains('seated')) s += 4;
        if ((n.contains('mobility') || n.contains('physical')) &&
            e.discipline == 'physiotherapy') {
          s += 2;
        }
      }
      return s;
    }

    final copy = [...all]..sort((a, b) => score(b).compareTo(score(a)));
    return copy.take(8).toList();
  }

  int streak(List<RehabLog> logs) {
    var n = 0;
    final days = logs
        .where((l) => l.percent > 0)
        .map((l) => DateTime(l.day.year, l.day.month, l.day.day))
        .toSet();
    var cursor = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    while (days.contains(cursor)) {
      n++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return n;
  }

  int consistency(List<RehabLog> logs) {
    if (logs.isEmpty) return 0;
    final recent = logs.length >= 7 ? logs.sublist(logs.length - 7) : logs;
    final avg = recent.fold<int>(0, (s, e) => s + e.percent) / recent.length;
    return avg.round();
  }

  List<double> weekBars(List<RehabLog> logs) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    return [
      for (var i = 0; i < 7; i++)
        () {
          final day = DateTime(start.year, start.month, start.day + i);
          for (final l in logs) {
            final d = DateTime(l.day.year, l.day.month, l.day.day);
            if (d == day) return (l.percent / 100).clamp(0.05, 1.0);
          }
          return 0.08;
        }(),
    ];
  }

  Future<int> ensureCatalog() async {
    var n = 0;
    for (final e in seedExercises) {
      final ref = _exercises.doc(e.id);
      if (!(await ref.get()).exists) {
        await ref.set({...e.toMap(), 'seeded': true});
        n++;
      }
    }
    for (final p in seedPrograms) {
      final ref = _programs.doc(p.id);
      if (!(await ref.get()).exists) {
        await ref.set({...p.toMap(), 'seeded': true});
        n++;
      }
    }
    return n;
  }

  Future<void> ensureUserSeed(UserProfile? profile) async {
    await ensureCatalog();
    final id = uid;
    if (id == null) return;
    final plan = _userCol('rehabPlan');
    if (plan == null) return;
    final existing = await plan.limit(1).get();
    if (existing.docs.isEmpty) {
      final all = (await _exercises.get()).docs.map(RehabExercise.fromDoc);
      final picks = personalized(all.toList(), profile);
      for (var i = 0; i < picks.length && i < 3; i++) {
        await plan.doc(picks[i].id).set({
          'exerciseId': picks[i].id,
          'status': i == 0
              ? 'done'
              : i == 1
              ? 'inProgress'
              : 'pending',
          'completedSets': i == 0 ? picks[i].sets : (i == 1 ? 2 : 0),
        });
      }
    }
    final goals = _userCol('rehabGoals')!;
    if ((await goals.limit(1).get()).docs.isEmpty) {
      await goals.add({
        'title': 'Walk 10 minutes without rest',
        'target': 'Week 4',
        'progress': 40,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await goals.add({
        'title': 'Complete daily home plan 5 days a week',
        'target': 'This month',
        'progress': 60,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    final notes = _userCol('rehabNotes')!;
    if ((await notes.limit(1).get()).docs.isEmpty) {
      await notes.add({
        'author': 'James Okonkwo, PT',
        'body':
            'Keep seated rows slow on the eccentric. Pause if pain > 4/10. Next session: gait + shoulder.',
        'appointmentId': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    final reminders = _userCol('rehabReminders')!;
    if ((await reminders.limit(1).get()).docs.isEmpty) {
      await reminders.add({
        'title': 'Home exercise plan',
        'whenLabel': 'Today, 6:00 PM',
        'kind': 'exercise',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await reminders.add({
        'title': 'Video session with your therapist',
        'whenLabel': 'Tomorrow, check Appointments',
        'kind': 'session',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    final logs = _userCol('rehabLogs')!;
    if ((await logs.limit(1).get()).docs.isEmpty) {
      final now = DateTime.now();
      const pcts = [35, 45, 40, 55, 62, 78, 70];
      for (var i = 6; i >= 0; i--) {
        final day = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: i));
        final key =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        await logs.doc(key).set({
          'day': Timestamp.fromDate(day),
          'percent': pcts[6 - i],
        });
      }
    }
  }
}

final seedExercises = <RehabExercise>[
  RehabExercise(
    id: 'seated-row',
    title: 'Seated Row',
    category: 'upper',
    discipline: 'physiotherapy',
    meta: 'Strength • Upper Body',
    sets: 3,
    reps: 12,
    minutes: 10,
    imageUrl:
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&h=400&fit=crop',
    tags: ['seated', 'wheelchair', 'mobility', 'shoulder'],
    demoCue: 'Pull elbows back, squeeze shoulder blades, sit tall.',
    steps: const [
      'Sit with a long spine, feet or footplates stable.',
      'Hold the band or handles at chest height.',
      'Pull elbows back without shrugging.',
      'Pause, then return slowly.',
    ],
  ),
  RehabExercise(
    id: 'leg-extensions',
    title: 'Leg Extensions',
    category: 'lower',
    discipline: 'physiotherapy',
    meta: 'Strength • Lower Body',
    sets: 3,
    reps: 15,
    minutes: 12,
    imageUrl:
        'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=600&h=400&fit=crop',
    tags: ['seated', 'wheelchair', 'mobility', 'knee'],
    demoCue: 'Straighten the knee fully, then lower with control.',
    steps: const [
      'Sit back in the chair with thighs supported.',
      'Straighten one knee until the thigh is tight.',
      'Hold 2 seconds, then lower.',
      'Alternate legs.',
    ],
  ),
  RehabExercise(
    id: 'breathing',
    title: 'Breathing Exercise',
    category: 'breathing',
    discipline: 'speech',
    meta: 'Mindfulness • Breathing',
    sets: 1,
    reps: 0,
    minutes: 5,
    imageUrl:
        'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=600&h=400&fit=crop',
    tags: ['cognitive', 'speech', 'sensory'],
    demoCue: 'Inhale 4, hold 4, exhale 6. Relax the shoulders.',
    steps: const [
      'Rest a hand on your belly.',
      'Breathe in through the nose for 4.',
      'Hold for 4.',
      'Exhale slowly for 6.',
    ],
  ),
  RehabExercise(
    id: 'sit-to-stand',
    title: 'Sit to Stand',
    category: 'lower',
    discipline: 'physiotherapy',
    meta: 'Strength • Functional',
    sets: 2,
    reps: 8,
    minutes: 8,
    imageUrl:
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600&h=400&fit=crop',
    tags: ['mobility', 'balance'],
    demoCue: 'Nose over toes, push through the legs, use the chair if needed.',
    steps: const [
      'Scoot forward on the chair.',
      'Lean the nose over the toes.',
      'Stand up, then sit slowly.',
    ],
  ),
  RehabExercise(
    id: 'shoulder-blade',
    title: 'Shoulder blade squeezes',
    category: 'upper',
    discipline: 'physiotherapy',
    meta: 'Mobility • Posture',
    sets: 2,
    reps: 10,
    minutes: 6,
    imageUrl:
        'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=600&h=400&fit=crop',
    tags: ['seated', 'shoulder', 'wheelchair'],
    demoCue: 'Gently squeeze blades together without lifting shoulders.',
    steps: const [
      'Sit or stand tall.',
      'Squeeze shoulder blades down and back.',
      'Hold 3 seconds.',
    ],
  ),
  RehabExercise(
    id: 'hamstring-stretch',
    title: 'Supported hamstring stretch',
    category: 'flexibility',
    discipline: 'physiotherapy',
    meta: 'Flexibility • Lower Body',
    sets: 2,
    reps: 0,
    minutes: 6,
    imageUrl:
        'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=600&h=400&fit=crop',
    tags: ['flexibility', 'mobility'],
    demoCue: 'Hinge at the hips, long spine, no bouncing.',
    steps: const [
      'Extend one leg with a slight knee bend.',
      'Hinge forward until a gentle stretch.',
      'Hold 20–30 seconds.',
    ],
  ),
  RehabExercise(
    id: 'band-press',
    title: 'Theraband chest press',
    category: 'strength',
    discipline: 'physiotherapy',
    meta: 'Strength • Chest',
    sets: 3,
    reps: 10,
    minutes: 8,
    imageUrl:
        'https://images.unsplash.com/photo-1434682881908-b43d0467b798?w=600&h=400&fit=crop',
    tags: ['seated', 'strength', 'wheelchair'],
    demoCue: 'Press forward, keep wrists straight.',
    steps: const [
      'Anchor the band behind you.',
      'Press both hands forward to chest height.',
      'Return slowly.',
    ],
  ),
  RehabExercise(
    id: 'reach-shelf',
    title: 'Supported reach to shelf',
    category: 'upper',
    discipline: 'occupational',
    meta: 'OT • Daily living',
    sets: 2,
    reps: 8,
    minutes: 7,
    imageUrl:
        'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600&h=400&fit=crop',
    tags: ['adl', 'occupational', 'visual'],
    demoCue: 'Reach with a stable base. Pause at the top.',
    steps: const [
      'Stand or sit near a counter.',
      'Reach a light object to a mid-shelf.',
      'Lower with control.',
    ],
  ),
  RehabExercise(
    id: 'hand-therapy',
    title: 'Putty grip and spread',
    category: 'strength',
    discipline: 'occupational',
    meta: 'OT • Hand therapy',
    sets: 3,
    reps: 12,
    minutes: 8,
    imageUrl:
        'https://images.unsplash.com/photo-1582719471384-894fbb16e074?w=600&h=400&fit=crop',
    tags: ['hand', 'occupational', 'fine-motor'],
    demoCue: 'Squeeze, then spread fingers against the putty.',
    steps: const [
      'Warm the putty in your hands.',
      'Grip 5 seconds, release.',
      'Spread fingers into the putty.',
    ],
  ),
  RehabExercise(
    id: 'lip-seal',
    title: 'Lip seal and puff',
    category: 'speech',
    discipline: 'speech',
    meta: 'Speech • Oral motor',
    sets: 3,
    reps: 8,
    minutes: 6,
    imageUrl:
        'https://images.unsplash.com/photo-1516542076529-1ea3854896f2?w=600&h=400&fit=crop',
    tags: ['speech', 'hearing'],
    demoCue: 'Close lips firmly, puff cheeks, hold, then release.',
    steps: const [
      'Sit upright.',
      'Press lips together.',
      'Puff cheeks for 3 seconds.',
      'Release and rest.',
    ],
  ),
  RehabExercise(
    id: 'articulation',
    title: 'Clear speech drill',
    category: 'speech',
    discipline: 'speech',
    meta: 'Speech • Articulation',
    sets: 2,
    reps: 10,
    minutes: 8,
    imageUrl:
        'https://images.unsplash.com/photo-1588196749597-9ff075ee6b5b?w=600&h=400&fit=crop',
    tags: ['speech', 'cognitive'],
    demoCue: 'Over-articulate each word. Pause between phrases.',
    steps: const [
      'Take a breath.',
      'Say the target phrase slowly.',
      'Repeat with a slightly faster pace.',
    ],
  ),
  RehabExercise(
    id: 'neck-reset',
    title: 'Gentle neck reset',
    category: 'flexibility',
    discipline: 'physiotherapy',
    meta: 'Flexibility • Neck',
    sets: 2,
    reps: 6,
    minutes: 5,
    imageUrl:
        'https://images.unsplash.com/photo-1518611645803-0444fb922ab7?w=600&h=400&fit=crop',
    tags: ['seated', 'pain', 'wheelchair'],
    demoCue: 'Small range only. Stop if dizzy.',
    steps: const [
      'Look forward.',
      'Slowly turn to one side.',
      'Return to center.',
    ],
  ),
];

final seedPrograms = <RehabProgram>[
  RehabProgram(
    id: 'post-op-mobility',
    title: 'Post-op mobility (4 weeks)',
    discipline: 'physiotherapy',
    summary: 'Seated strength, gait prep, and breathing after surgery.',
    weeks: 4,
    exerciseIds: ['seated-row', 'leg-extensions', 'sit-to-stand', 'breathing'],
    goal: 'Safer transfers and 10-minute walks',
  ),
  RehabProgram(
    id: 'adl-ot',
    title: 'Daily living OT',
    discipline: 'occupational',
    summary: 'Reach, grip, and energy conservation for home tasks.',
    weeks: 6,
    exerciseIds: ['reach-shelf', 'hand-therapy', 'shoulder-blade'],
    goal: 'Independent kitchen and dressing tasks',
  ),
  RehabProgram(
    id: 'speech-clarity',
    title: 'Speech & breath support',
    discipline: 'speech',
    summary: 'Oral-motor, breath, and clear-speech practice.',
    weeks: 8,
    exerciseIds: ['breathing', 'lip-seal', 'articulation'],
    goal: 'Clearer conversation with less fatigue',
  ),
];
