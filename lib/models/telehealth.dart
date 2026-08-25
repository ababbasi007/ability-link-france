import 'package:cloud_firestore/cloud_firestore.dart';

class HealthVital {
  const HealthVital({
    required this.id,
    required this.heartRate,
    required this.systolic,
    required this.diastolic,
    required this.weightKg,
    required this.sleepHours,
    required this.createdAt,
    this.note = '',
  });

  final String id;
  final int heartRate;
  final int systolic;
  final int diastolic;
  final double weightKg;
  final double sleepHours;
  final DateTime createdAt;
  final String note;

  String get bpLabel => '$systolic/$diastolic';
  String get hrLabel => '$heartRate bpm';
  String get weightLabel => '${weightKg.toStringAsFixed(0)} kg';
  String get sleepLabel => '${sleepHours.toStringAsFixed(1)} hrs';

  String get hrStatus =>
      heartRate >= 60 && heartRate <= 100 ? 'Normal' : 'Check';
  String get bpStatus =>
      systolic <= 120 && diastolic <= 80 ? 'Normal' : 'Watch';
  String get weightStatus => 'Logged';
  String get sleepStatus => sleepHours >= 7 ? 'Good' : 'Low';

  factory HealthVital.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return HealthVital(
      id: doc.id,
      heartRate: (d['heartRate'] as num?)?.toInt() ?? 0,
      systolic: (d['systolic'] as num?)?.toInt() ?? 0,
      diastolic: (d['diastolic'] as num?)?.toInt() ?? 0,
      weightKg: (d['weightKg'] as num?)?.toDouble() ?? 0,
      sleepHours: (d['sleepHours'] as num?)?.toDouble() ?? 0,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      note: (d['note'] as String?) ?? '',
    );
  }
}

class MedicalHistoryItem {
  const MedicalHistoryItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.createdAt,
  });

  final String id;

  /// condition | allergy | surgery | immunization | other
  final String kind;
  final String title;
  final String detail;
  final DateTime createdAt;

  factory MedicalHistoryItem.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return MedicalHistoryItem(
      id: doc.id,
      kind: (d['kind'] as String?) ?? 'other',
      title: (d['title'] as String?) ?? '',
      detail: (d['detail'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

class Prescription {
  const Prescription({
    required this.id,
    required this.name,
    required this.dose,
    required this.frequency,
    required this.prescriber,
    required this.active,
    required this.createdAt,
    this.notes = '',
  });

  final String id;
  final String name;
  final String dose;
  final String frequency;
  final String prescriber;
  final bool active;
  final DateTime createdAt;
  final String notes;

  factory Prescription.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return Prescription(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      dose: (d['dose'] as String?) ?? '',
      frequency: (d['frequency'] as String?) ?? '',
      prescriber: (d['prescriber'] as String?) ?? '',
      active: d['active'] != false,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      notes: (d['notes'] as String?) ?? '',
    );
  }
}

class MedicalDocument {
  const MedicalDocument({
    required this.id,
    required this.title,
    required this.kind,
    required this.detail,
    required this.createdAt,
    this.fileUrl = '',
    this.fileName = '',
    this.contentType = '',
    this.storagePath = '',
  });

  final String id;
  final String title;

  /// lab | scan | insurance | visit | other
  final String kind;
  final String detail;
  final DateTime createdAt;
  final String fileUrl;
  final String fileName;
  final String contentType;
  final String storagePath;

  bool get hasFile => fileUrl.isNotEmpty;
  bool get isImage => contentType.startsWith('image/');

  factory MedicalDocument.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return MedicalDocument(
      id: doc.id,
      title: (d['title'] as String?) ?? 'Document',
      kind: (d['kind'] as String?) ?? 'other',
      detail: (d['detail'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      fileUrl: (d['fileUrl'] as String?) ?? '',
      fileName: (d['fileName'] as String?) ?? '',
      contentType: (d['contentType'] as String?) ?? '',
      storagePath: (d['storagePath'] as String?) ?? '',
    );
  }
}

class DoctorNote {
  const DoctorNote({
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

  factory DoctorNote.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return DoctorNote(
      id: doc.id,
      author: (d['author'] as String?) ?? 'Doctor',
      body: (d['body'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      appointmentId: (d['appointmentId'] as String?) ?? '',
    );
  }
}

class MedReminder {
  const MedReminder({
    required this.id,
    required this.title,
    required this.whenLabel,
    required this.kind,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String whenLabel;
  final String kind;
  final DateTime createdAt;

  factory MedReminder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return MedReminder(
      id: doc.id,
      title: (d['title'] as String?) ?? '',
      whenLabel: (d['whenLabel'] as String?) ?? '',
      kind: (d['kind'] as String?) ?? 'medicine',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

class TelehealthSpecialty {
  const TelehealthSpecialty({required this.name, required this.icon});

  final String name;
  final String icon;

  static const catalog = [
    TelehealthSpecialty(name: 'General Physician', icon: 'stethoscope'),
    TelehealthSpecialty(name: 'Neurologist', icon: 'neurology'),
    TelehealthSpecialty(name: 'Cardiologist', icon: 'heart'),
    TelehealthSpecialty(name: 'Dermatologist', icon: 'skin'),
    TelehealthSpecialty(name: 'Pediatrician', icon: 'child'),
    TelehealthSpecialty(name: 'Psychiatrist', icon: 'mind'),
  ];
}
