import 'package:cloud_firestore/cloud_firestore.dart';

class PlatformConfig {
  const PlatformConfig({
    required this.adminUids,
    required this.moderatorUids,
    required this.placeCategories,
    required this.providerCategories,
    this.maintenanceMessage = '',
  });

  final List<String> adminUids;
  final List<String> moderatorUids;
  final List<String> placeCategories;
  final List<String> providerCategories;
  final String maintenanceMessage;

  bool isAdmin(String? uid) => uid != null && adminUids.contains(uid);
  bool isModerator(String? uid) =>
      isAdmin(uid) || (uid != null && moderatorUids.contains(uid));

  factory PlatformConfig.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return PlatformConfig(
      adminUids: List<String>.from(d['adminUids'] as List? ?? const []),
      moderatorUids: List<String>.from(d['moderatorUids'] as List? ?? const []),
      placeCategories: List<String>.from(
        d['placeCategories'] as List? ??
            const [
              'hospital',
              'cafe',
              'library',
              'mall',
              'transit',
              'park',
              'other',
            ],
      ),
      providerCategories: List<String>.from(
        d['providerCategories'] as List? ??
            const ['healthcare', 'rehab', 'education', 'caregiving', 'other'],
      ),
      maintenanceMessage: (d['maintenanceMessage'] as String?) ?? '',
    );
  }
}

class AdminUserRecord {
  const AdminUserRecord({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.accountStatus,
    required this.fraudScore,
    required this.onboardingComplete,
    this.platformRole = '',
    this.fraudNotes = '',
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final String accountStatus;
  final int fraudScore;
  final bool onboardingComplete;
  final String platformRole;
  final String fraudNotes;

  factory AdminUserRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final personal = d['personal'] is Map
        ? Map<String, dynamic>.from(d['personal'] as Map)
        : const <String, dynamic>{};
    final name = (d['fullName'] as String?)?.trim().isNotEmpty == true
        ? (d['fullName'] as String).trim()
        : '${personal['firstName'] ?? ''} ${personal['lastName'] ?? ''}'.trim();
    return AdminUserRecord(
      uid: doc.id,
      name: name.isEmpty ? 'User' : name,
      email: (d['email'] as String?) ?? '',
      role: (d['role'] as String?) ?? '',
      accountStatus: (d['accountStatus'] as String?) ?? 'active',
      fraudScore: (d['fraudScore'] as num?)?.toInt() ?? 0,
      onboardingComplete: d['onboardingComplete'] == true,
      platformRole: (d['platformRole'] as String?) ?? '',
      fraudNotes: (d['fraudNotes'] as String?) ?? '',
    );
  }
}

class ModerationItem {
  const ModerationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.flagCount,
  });

  final String id;
  final String kind;
  final String title;
  final String subtitle;
  final String status;
  final int flagCount;
}
