import 'package:cloud_firestore/cloud_firestore.dart';

class RehabExercise {
  const RehabExercise({
    required this.id,
    required this.title,
    required this.category,
    required this.discipline,
    required this.meta,
    required this.sets,
    required this.reps,
    required this.minutes,
    required this.imageUrl,
    required this.steps,
    required this.tags,
    this.demoCue = '',
  });

  final String id;
  final String title;
  final String
  category; // upper, lower, flexibility, strength, breathing, speech
  final String discipline; // physiotherapy, occupational, speech
  final String meta;
  final int sets;
  final int reps;
  final int minutes;
  final String imageUrl;
  final List<String> steps;
  final List<String> tags;
  final String demoCue;

  factory RehabExercise.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return RehabExercise(
      id: doc.id,
      title: (d['title'] as String?) ?? 'Exercise',
      category: (d['category'] as String?) ?? 'strength',
      discipline: (d['discipline'] as String?) ?? 'physiotherapy',
      meta: (d['meta'] as String?) ?? '',
      sets: (d['sets'] as num?)?.toInt() ?? 1,
      reps: (d['reps'] as num?)?.toInt() ?? 0,
      minutes: (d['minutes'] as num?)?.toInt() ?? 5,
      imageUrl: (d['imageUrl'] as String?) ?? '',
      steps: List<String>.from(d['steps'] as List? ?? const []),
      tags: List<String>.from(d['tags'] as List? ?? const []),
      demoCue: (d['demoCue'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'category': category,
    'discipline': discipline,
    'meta': meta,
    'sets': sets,
    'reps': reps,
    'minutes': minutes,
    'imageUrl': imageUrl,
    'steps': steps,
    'tags': tags,
    'demoCue': demoCue,
  };
}

class RehabProgram {
  const RehabProgram({
    required this.id,
    required this.title,
    required this.discipline,
    required this.summary,
    required this.weeks,
    required this.exerciseIds,
    required this.goal,
  });

  final String id;
  final String title;
  final String discipline;
  final String summary;
  final int weeks;
  final List<String> exerciseIds;
  final String goal;

  factory RehabProgram.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return RehabProgram(
      id: doc.id,
      title: (d['title'] as String?) ?? 'Program',
      discipline: (d['discipline'] as String?) ?? 'physiotherapy',
      summary: (d['summary'] as String?) ?? '',
      weeks: (d['weeks'] as num?)?.toInt() ?? 4,
      exerciseIds: List<String>.from(d['exerciseIds'] as List? ?? const []),
      goal: (d['goal'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'discipline': discipline,
    'summary': summary,
    'weeks': weeks,
    'exerciseIds': exerciseIds,
    'goal': goal,
  };
}

class RehabPlanItem {
  const RehabPlanItem({
    required this.exerciseId,
    required this.status,
    this.completedSets = 0,
  });

  final String exerciseId;
  final String status; // done | inProgress | pending
  final int completedSets;

  factory RehabPlanItem.fromMap(String id, Map<String, dynamic> d) =>
      RehabPlanItem(
        exerciseId: id,
        status: (d['status'] as String?) ?? 'pending',
        completedSets: (d['completedSets'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
    'status': status,
    'completedSets': completedSets,
    'exerciseId': exerciseId,
  };
}

class RehabGoal {
  const RehabGoal({
    required this.id,
    required this.title,
    required this.target,
    required this.progress,
  });

  final String id;
  final String title;
  final String target;
  final int progress;

  factory RehabGoal.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return RehabGoal(
      id: doc.id,
      title: (d['title'] as String?) ?? 'Goal',
      target: (d['target'] as String?) ?? '',
      progress: (d['progress'] as num?)?.toInt() ?? 0,
    );
  }
}

class RehabHealthEntry {
  const RehabHealthEntry({
    required this.id,
    required this.pain,
    required this.energy,
    required this.mobility,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final int pain;
  final int energy;
  final int mobility;
  final String note;
  final DateTime createdAt;

  factory RehabHealthEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return RehabHealthEntry(
      id: doc.id,
      pain: (d['pain'] as num?)?.toInt() ?? 0,
      energy: (d['energy'] as num?)?.toInt() ?? 0,
      mobility: (d['mobility'] as num?)?.toInt() ?? 0,
      note: (d['note'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

class RehabNote {
  const RehabNote({
    required this.id,
    required this.author,
    required this.body,
    required this.createdAt,
    this.appointmentId = '',
  });

  final String id;
  final String author;
  final String body;
  final DateTime createdAt;
  final String appointmentId;

  factory RehabNote.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return RehabNote(
      id: doc.id,
      author: (d['author'] as String?) ?? 'Therapist',
      body: (d['body'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      appointmentId: (d['appointmentId'] as String?) ?? '',
    );
  }
}

class RehabReminder {
  const RehabReminder({
    required this.id,
    required this.title,
    required this.whenLabel,
    required this.kind,
  });

  final String id;
  final String title;
  final String whenLabel;
  final String kind;

  factory RehabReminder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return RehabReminder(
      id: doc.id,
      title: (d['title'] as String?) ?? 'Reminder',
      whenLabel: (d['whenLabel'] as String?) ?? '',
      kind: (d['kind'] as String?) ?? 'exercise',
    );
  }
}

class SessionChatMessage {
  const SessionChatMessage({
    required this.id,
    required this.uid,
    required this.author,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String uid;
  final String author;
  final String body;
  final DateTime createdAt;

  factory SessionChatMessage.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return SessionChatMessage(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      author: (d['author'] as String?) ?? 'You',
      body: (d['body'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

class RehabLog {
  const RehabLog({required this.id, required this.day, required this.percent});

  final String id;
  final DateTime day;
  final int percent;

  factory RehabLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['day'];
    return RehabLog(
      id: doc.id,
      day: ts is Timestamp ? ts.toDate() : DateTime.now(),
      percent: (d['percent'] as num?)?.toInt() ?? 0,
    );
  }
}
