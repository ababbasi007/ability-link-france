import 'package:cloud_firestore/cloud_firestore.dart';

class HealthOrg {
  const HealthOrg({
    required this.id,
    required this.name,
    required this.city,
    required this.kind,
    required this.about,
    required this.ownerUid,
  });

  final String id;
  final String name;
  final String city;

  /// clinic | hospital | rehab
  final String kind;
  final String about;
  final String ownerUid;

  String get kindLabel => switch (kind) {
    'hospital' => 'Hospital',
    'rehab' => 'Rehab network',
    _ => 'Clinic',
  };

  factory HealthOrg.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return HealthOrg(
      id: doc.id,
      name: (d['name'] as String?) ?? 'Clinic',
      city: (d['city'] as String?) ?? '',
      kind: (d['kind'] as String?) ?? 'clinic',
      about: (d['about'] as String?) ?? '',
      ownerUid: (d['ownerUid'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'city': city,
    'kind': kind,
    'about': about,
    'ownerUid': ownerUid,
  };
}

class OrgStaffMember {
  const OrgStaffMember({
    required this.providerId,
    required this.name,
    required this.specialty,
    required this.category,
  });

  final String providerId;
  final String name;
  final String specialty;
  final String category;

  @override
  bool operator ==(Object other) =>
      other is OrgStaffMember && other.providerId == providerId;

  @override
  int get hashCode => providerId.hashCode;

  factory OrgStaffMember.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return OrgStaffMember(
      providerId: doc.id,
      name: (d['name'] as String?) ?? 'Provider',
      specialty: (d['specialty'] as String?) ?? '',
      category: (d['category'] as String?) ?? '',
    );
  }
}

class PatientConsent {
  const PatientConsent({
    required this.id,
    required this.orgId,
    required this.uid,
    required this.patientName,
    required this.needs,
    required this.status,
    required this.createdAt,
    this.notes = '',
  });

  final String id;
  final String orgId;
  final String uid;
  final String patientName;
  final List<String> needs;
  final String status;
  final DateTime createdAt;
  final String notes;

  bool get isActive => status == 'active';

  @override
  bool operator ==(Object other) => other is PatientConsent && other.id == id;

  @override
  int get hashCode => id.hashCode;

  factory PatientConsent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return PatientConsent(
      id: doc.id,
      orgId: (d['orgId'] as String?) ?? '',
      uid: (d['uid'] as String?) ?? '',
      patientName: (d['patientName'] as String?) ?? 'Patient',
      needs: List<String>.from(d['needs'] as List? ?? const []),
      status: (d['status'] as String?) ?? 'active',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      notes: (d['notes'] as String?) ?? '',
    );
  }
}
