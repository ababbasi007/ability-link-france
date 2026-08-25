import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/place_qna.dart';

class PlaceQnaService {
  PlaceQnaService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('placeQna');

  Stream<List<PlaceQnaQuestion>> watchFor({
    required String targetType,
    required String targetId,
  }) async* {
    try {
      yield* _col
          .where('targetType', isEqualTo: targetType)
          .where('targetId', isEqualTo: targetId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map(PlaceQnaQuestion.fromDoc).toList());
    } catch (_) {
      yield const [];
    }
  }

  Future<void> ask({
    required String targetType,
    required String targetId,
    required String targetName,
    required String question,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to ask a question');
    final text = question.trim();
    if (text.isEmpty) throw StateError('Question cannot be empty');

    await _col.add({
      'targetType': targetType,
      'targetId': targetId,
      'targetName': targetName,
      'uid': user.uid,
      'authorName': user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'Ability Link user',
      'question': text,
      'answerUid': '',
      'answerBody': '',
      'answeredAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Allows the place owner or a moderator to post an answer.
  Future<void> answer({
    required String questionId,
    required String body,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to answer');
    final text = body.trim();
    if (text.isEmpty) throw StateError('Answer cannot be empty');

    await _col.doc(questionId).update({
      'answerUid': user.uid,
      'answerBody': text,
      'answeredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
