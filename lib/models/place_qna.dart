import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceQnaQuestion {
  const PlaceQnaQuestion({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.uid,
    required this.question,
    required this.createdAt,
    this.authorName = '',
    this.answerUid = '',
    this.answerBody = '',
    this.answeredAt,
    this.updatedAt,
  });

  final String id;

  /// Currently: place
  final String targetType;
  final String targetId;
  final String targetName;

  /// Question author.
  final String uid;
  final String authorName;
  final String question;

  final DateTime createdAt;

  /// Optional answer fields. If [answerBody] is empty, treat as unanswered.
  final String answerUid;
  final String answerBody;
  final DateTime? answeredAt;

  final DateTime? updatedAt;

  bool get isAnswered => answerBody.trim().isNotEmpty;

  factory PlaceQnaQuestion.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final created = d['createdAt'];
    final answered = d['answeredAt'];
    final updated = d['updatedAt'];

    return PlaceQnaQuestion(
      id: doc.id,
      targetType: (d['targetType'] as String?) ?? 'place',
      targetId: (d['targetId'] as String?) ?? '',
      targetName: (d['targetName'] as String?) ?? '',
      uid: (d['uid'] as String?) ?? '',
      authorName: (d['authorName'] as String?) ?? '',
      question: (d['question'] as String?) ?? '',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      answerUid: (d['answerUid'] as String?) ?? '',
      answerBody: (d['answerBody'] as String?) ?? '',
      answeredAt: answered is Timestamp ? answered.toDate() : null,
      updatedAt: updated is Timestamp ? updated.toDate() : null,
    );
  }
}
