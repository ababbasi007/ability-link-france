import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/place_barrier_report.dart';
import '../models/place_report.dart';

/// Local video picked for a barrier report before upload.
class ReportVideoAttachment {
  const ReportVideoAttachment({
    required this.bytes,
    required this.extension,
    this.fileName = '',
  });

  final Uint8List bytes;
  final String extension;
  final String fileName;

  String get contentType => switch (extension.toLowerCase()) {
    'mov' => 'video/quicktime',
    'm4v' => 'video/x-m4v',
    _ => 'video/mp4',
  };
}

class PlaceReportService {
  PlaceReportService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _db = db ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  static const maxPhotos = 3;
  static const maxVideos = 1;
  static const maxPhotoBytes = 8 * 1024 * 1024;
  static const maxVideoBytes = 50 * 1024 * 1024;

  /// Submits a structured barrier or listing report with optional media evidence.
  Future<String> submit({
    required String placeId,
    required String placeName,
    required String category,
    required String details,
    List<Uint8List> photoBytes = const [],
    List<ReportVideoAttachment> videoAttachments = const [],
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in to report a place issue');
    }
    if (PlaceBarrierCategory.byId(category) == null) {
      throw StateError('Choose a report category');
    }
    if (details.trim().isEmpty &&
        photoBytes.isEmpty &&
        videoAttachments.isEmpty) {
      throw StateError('Add a short description or photo/video evidence');
    }
    if (photoBytes.length > maxPhotos) {
      throw StateError('You can attach up to $maxPhotos photos');
    }
    if (videoAttachments.length > maxVideos) {
      throw StateError('You can attach up to $maxVideos video');
    }

    final ref = _db.collection('placeReports').doc();
    final photoUrls = <String>[];
    for (var i = 0; i < photoBytes.length; i++) {
      final bytes = photoBytes[i];
      if (bytes.length > maxPhotoBytes) {
        throw StateError('Each photo must be under 8 MB');
      }
      final path = 'placeReports/$uid/${ref.id}/photo_$i.jpg';
      final storageRef = _storage.ref(path);
      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      photoUrls.add(await storageRef.getDownloadURL());
    }

    final videoUrls = <String>[];
    for (var i = 0; i < videoAttachments.length; i++) {
      final video = videoAttachments[i];
      if (video.bytes.length > maxVideoBytes) {
        throw StateError('Video must be under 50 MB');
      }
      final ext = video.extension.isEmpty ? 'mp4' : video.extension;
      final path = 'placeReports/$uid/${ref.id}/video_$i.$ext';
      final storageRef = _storage.ref(path);
      await storageRef.putData(
        video.bytes,
        SettableMetadata(contentType: video.contentType),
      );
      videoUrls.add(await storageRef.getDownloadURL());
    }

    await ref.set({
      ...placeReportDocument(
        uid: uid,
        placeId: placeId,
        placeName: placeName,
        category: category,
        details: details,
        photoUrls: photoUrls,
        videoUrls: videoUrls,
      ),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<PlaceReport>> watchMine() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _db
        .collection('placeReports')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final rows = snap.docs
              .map((d) => PlaceReport.fromMap(d.id, d.data()))
              .toList();
          rows.sort((a, b) {
            final at = a.createdAt;
            final bt = b.createdAt;
            if (at != null && bt != null) return bt.compareTo(at);
            if (at != null) return -1;
            if (bt != null) return 1;
            return 0;
          });
          return rows;
        });
  }

  /// One-shot fetch of the user's open / in-review reports.
  ///
  /// Used for lightweight routing detours (Phase 3 v1).
  Future<List<PlaceReport>> fetchMineOpenAndInReview() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const [];

    final snap = await _db
        .collection('placeReports')
        .where('uid', isEqualTo: uid)
        .get();

    final rows = snap.docs
        .map((d) => PlaceReport.fromMap(d.id, d.data()))
        .toList();

    return rows.where((r) {
      return r.status == PlaceReportStatus.open ||
          r.status == PlaceReportStatus.inReview;
    }).toList();
  }
}
