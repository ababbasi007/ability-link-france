import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/remote_image_url.dart';

class CareAppointment {
  const CareAppointment({
    required this.id,
    required this.uid,
    required this.providerId,
    required this.providerName,
    required this.specialty,
    required this.kind,
    required this.mode,
    required this.startAt,
    required this.durationMin,
    required this.status,
    this.notes = '',
    this.photoUrl = '',
    this.orgId = '',
    this.patientName = '',
    this.summary = '',
    this.followUpOf = '',
    this.joinCode = '',
  });

  final String id;
  final String uid;
  final String providerId;
  final String providerName;
  final String specialty;

  /// telehealth | rehab | clinic
  final String kind;

  /// video | audio | chat | in-clinic | home
  final String mode;
  final DateTime startAt;
  final int durationMin;

  /// booked | completed | cancelled
  final String status;
  final String notes;
  final String photoUrl;
  final String orgId;
  final String patientName;
  final String summary;
  final String followUpOf;
  final String joinCode;

  bool get isUpcoming =>
      status == 'booked' &&
      startAt.isAfter(DateTime.now().subtract(const Duration(hours: 1)));

  bool get isRemote => mode == 'video' || mode == 'audio' || mode == 'chat';

  bool get canJoin =>
      status == 'booked' &&
      isRemote &&
      DateTime.now().isAfter(startAt.subtract(const Duration(minutes: 30))) &&
      DateTime.now().isBefore(startAt.add(Duration(minutes: durationMin + 15)));

  String get modeLabel => switch (mode) {
    'in-clinic' => 'Clinic visit',
    'home' => 'Home visit',
    'audio' => 'Audio consultation',
    'chat' => 'Chat consultation',
    _ => 'Video consultation',
  };

  String get kindLabel => switch (kind) {
    'rehab' => 'Rehabilitation',
    'clinic' => 'Clinic',
    _ => 'Telehealth',
  };

  String get whenLabel {
    final now = DateTime.now();
    final local = startAt.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today, $time';
    if (diff == 1) return 'Tomorrow, $time';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, $time';
  }

  factory CareAppointment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['startAt'];
    return CareAppointment(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      providerId: (d['providerId'] as String?) ?? '',
      providerName: (d['providerName'] as String?) ?? 'Provider',
      specialty: (d['specialty'] as String?) ?? '',
      kind: (d['kind'] as String?) ?? 'telehealth',
      mode: (d['mode'] as String?) ?? 'video',
      startAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      durationMin: (d['durationMin'] as num?)?.toInt() ?? 30,
      status: (d['status'] as String?) ?? 'booked',
      notes: (d['notes'] as String?) ?? '',
      photoUrl: sanitizeRemoteImageUrl((d['photoUrl'] as String?) ?? ''),
      orgId: (d['orgId'] as String?) ?? '',
      patientName: (d['patientName'] as String?) ?? '',
      summary: (d['summary'] as String?) ?? '',
      followUpOf: (d['followUpOf'] as String?) ?? '',
      joinCode: (d['joinCode'] as String?) ?? '',
    );
  }
}

class CareReferral {
  const CareReferral({
    required this.id,
    required this.uid,
    required this.fromName,
    required this.toSpecialty,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.matchedProviderId = '',
    this.matchedProviderName = '',
    this.orgId = '',
    this.patientName = '',
  });

  final String id;
  final String uid;
  final String fromName;
  final String toSpecialty;
  final String reason;

  /// requested | matched
  final String status;
  final DateTime createdAt;
  final String matchedProviderId;
  final String matchedProviderName;
  final String orgId;
  final String patientName;

  factory CareReferral.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return CareReferral(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      fromName: (d['fromName'] as String?) ?? 'Self-referral',
      toSpecialty: (d['toSpecialty'] as String?) ?? '',
      reason: (d['reason'] as String?) ?? '',
      status: (d['status'] as String?) ?? 'requested',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      matchedProviderId: (d['matchedProviderId'] as String?) ?? '',
      matchedProviderName: (d['matchedProviderName'] as String?) ?? '',
      orgId: (d['orgId'] as String?) ?? '',
      patientName: (d['patientName'] as String?) ?? '',
    );
  }
}
