import 'package:cloud_firestore/cloud_firestore.dart';

/// Aggregates anonymous visit timestamps per place for busy-hour hints.
class PlaceVisitStatsService {
  PlaceVisitStatsService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('placeVisitStats');

  /// Records a visit hour bucket for [placeId] (best-effort, no auth required).
  Future<void> recordVisit(String placeId) async {
    if (placeId.isEmpty) return;
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday;
    try {
      await _col.doc(placeId).set({
        'hours.$hour': FieldValue.increment(1),
        'weekday.$weekday.$hour': FieldValue.increment(1),
        'totalVisits': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Returns a human-readable peak-time label, or null if insufficient data.
  Future<String?> peakHoursLabel(String placeId) async {
    if (placeId.isEmpty) return null;
    try {
      final snap = await _col.doc(placeId).get();
      if (!snap.exists) return null;
      final data = snap.data() ?? {};
      final total = (data['totalVisits'] as num?)?.toInt() ?? 0;
      if (total < 5) return null;

      final hoursRaw = data['hours'];
      if (hoursRaw is! Map) return null;

      var peakHour = 0;
      var peakCount = 0;
      hoursRaw.forEach((key, value) {
        final h = int.tryParse(key.toString()) ?? -1;
        final c = (value as num?)?.toInt() ?? 0;
        if (c > peakCount) {
          peakCount = c;
          peakHour = h;
        }
      });
      if (peakCount == 0) return null;

      final start = _formatHour(peakHour);
      final end = _formatHour((peakHour + 1) % 24);
      return 'Usually busiest $start–$end';
    } catch (_) {
      return null;
    }
  }

  String _formatHour(int hour) {
    final h = hour % 24;
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }
}
