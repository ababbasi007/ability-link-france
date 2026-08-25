import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPrefs {
  const NotificationPrefs({
    this.inApp = true,
    this.push = true,
    this.email = true,
    this.sms = false,
    this.bookings = true,
    this.payments = true,
    this.caregiver = true,
    this.telehealth = true,
    this.rehab = true,
    this.exercise = true,
    this.benefits = true,
    this.nearby = true,
    this.messages = true,
    this.emergency = true,
    this.barriers = true,
    this.savedSearch = true,
  });

  final bool inApp;
  final bool push;
  final bool email;
  final bool sms;
  final bool bookings;
  final bool payments;
  final bool caregiver;
  final bool telehealth;
  final bool rehab;
  final bool exercise;
  final bool benefits;
  final bool nearby;
  final bool messages;
  final bool emergency;
  final bool barriers;
  final bool savedSearch;

  bool allows(String type) {
    if (!inApp) return false;
    return switch (type) {
      'booking' || 'appointment' => bookings,
      'payment' => payments,
      'caregiver' => caregiver,
      'telehealth' || 'prescription' => telehealth,
      'rehab' => rehab,
      'exercise' => exercise,
      'reminder' => telehealth || rehab || exercise,
      'benefit_reminder' => benefits,
      'nearby' => nearby,
      'message' => messages,
      'sos' => emergency,
      'barrier' => barriers,
      'saved_search' => savedSearch,
      _ => true,
    };
  }

  String get channelsLabel {
    final on = <String>[
      if (inApp) 'In-app',
      if (push) 'Push',
      if (email) 'Email',
      if (sms) 'SMS',
    ];
    return on.isEmpty ? 'All channels off' : on.join(' · ');
  }

  factory NotificationPrefs.fromMap(Map<String, dynamic>? data) {
    final d = data ?? const {};
    bool flag(String k, bool fallback) =>
        d[k] == null ? fallback : d[k] == true;
    return NotificationPrefs(
      inApp: flag('inApp', true),
      push: flag('push', true),
      email: flag('email', true),
      sms: flag('sms', false),
      bookings: flag('bookings', true),
      payments: flag('payments', true),
      caregiver: flag('caregiver', true),
      telehealth: flag('telehealth', true),
      rehab: flag('rehab', true),
      exercise: flag('exercise', true),
      benefits: flag('benefits', true),
      nearby: flag('nearby', true),
      messages: flag('messages', true),
      emergency: flag('emergency', true),
      barriers: flag('barriers', true),
      savedSearch: flag('savedSearch', true),
    );
  }

  Map<String, dynamic> toMap() => {
    'inApp': inApp,
    'push': push,
    'email': email,
    'sms': sms,
    'bookings': bookings,
    'payments': payments,
    'caregiver': caregiver,
    'telehealth': telehealth,
    'rehab': rehab,
    'exercise': exercise,
    'benefits': benefits,
    'nearby': nearby,
    'messages': messages,
    'emergency': emergency,
    'barriers': barriers,
    'savedSearch': savedSearch,
  };

  NotificationPrefs copyWith({
    bool? inApp,
    bool? push,
    bool? email,
    bool? sms,
    bool? bookings,
    bool? payments,
    bool? caregiver,
    bool? telehealth,
    bool? rehab,
    bool? exercise,
    bool? benefits,
    bool? nearby,
    bool? messages,
    bool? emergency,
    bool? barriers,
    bool? savedSearch,
  }) {
    return NotificationPrefs(
      inApp: inApp ?? this.inApp,
      push: push ?? this.push,
      email: email ?? this.email,
      sms: sms ?? this.sms,
      bookings: bookings ?? this.bookings,
      payments: payments ?? this.payments,
      caregiver: caregiver ?? this.caregiver,
      telehealth: telehealth ?? this.telehealth,
      rehab: rehab ?? this.rehab,
      exercise: exercise ?? this.exercise,
      benefits: benefits ?? this.benefits,
      nearby: nearby ?? this.nearby,
      messages: messages ?? this.messages,
      emergency: emergency ?? this.emergency,
      barriers: barriers ?? this.barriers,
      savedSearch: savedSearch ?? this.savedSearch,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.uid,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.relatedId = '',
    this.channels = const ['inApp'],
  });

  final String id;
  final String uid;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String relatedId;
  final List<String> channels;

  String get typeLabel => switch (type) {
    'booking' || 'appointment' => 'Booking',
    'payment' => 'Payment',
    'caregiver' => 'Caregiver',
    'telehealth' || 'prescription' => 'Telehealth',
    'rehab' => 'Rehab',
    'exercise' => 'Exercise',
    'reminder' => 'Reminder',
    'benefit_reminder' => 'Benefits',
    'nearby' => 'Nearby',
    'message' => 'Message',
    'sos' => 'Emergency',
    'barrier' => 'Barrier',
    'saved_search' => 'Search',
    _ => 'Alert',
  };

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return AppNotification(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      type: (d['type'] as String?) ?? 'general',
      title: (d['title'] as String?) ?? 'Notification',
      body: (d['body'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      read: d['read'] == true,
      relatedId: (d['relatedId'] as String?) ?? '',
      channels: List<String>.from(d['channels'] as List? ?? const ['inApp']),
    );
  }
}

class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.query,
    required this.need,
    required this.createdAt,
  });

  final String id;
  final String query;
  final String need;
  final DateTime createdAt;

  String get label => query.trim().isEmpty ? 'Need: $need' : '$query · $need';

  factory SavedSearch.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return SavedSearch(
      id: doc.id,
      query: (d['query'] as String?) ?? '',
      need: (d['need'] as String?) ?? 'all',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
