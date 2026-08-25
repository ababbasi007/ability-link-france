import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/telehealth.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/healthcare_service.dart';
import '../../services/providers_service.dart';
import '../../services/telehealth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/decoded_network_image.dart';
import '../../models/service_provider.dart';
import '../healthcare/appointments_screen.dart';
import '../healthcare/session_room_screen.dart';
import '../notifications/notifications_inbox_screen.dart';
import '../providers/providers_directory_screen.dart';

class TelehealthSpecialtiesScreen extends StatelessWidget {
  const TelehealthSpecialtiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Medical specialties',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          for (final s in TelehealthSpecialty.catalog)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.medical_services, color: AppColors.primary),
                ),
                title: Text(
                  s.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text('Find doctors in this specialty'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ProvidersDirectoryScreen(
                      initialCategory: 'Healthcare',
                      initialSpecialty: s.name,
                      title: s.name,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MedicalHistoryScreen extends StatelessWidget {
  const MedicalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tele = TelehealthService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Medical history',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const DoctorNotesScreen(),
              ),
            ),
            child: const Text('Notes'),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AppointmentsScreen(),
              ),
            ),
            child: const Text('Visits'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, tele),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: StreamBuilder<UserProfile?>(
        stream: AuthService().watchCurrentProfile(),
        builder: (context, profileSnap) {
          final p = profileSnap.data;
          return StreamBuilder<List<MedicalHistoryItem>>(
            stream: tele.watchHistory(),
            builder: (context, snap) {
              final list = snap.data ?? const <MedicalHistoryItem>[];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                children: [
                  if (p != null) ...[
                    Text(
                      'Passport · ${p.bloodGroup} · ${p.accessibilityProfiles.isEmpty ? 'no access tags' : p.accessibilityProfiles.join(', ')}',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (list.isEmpty)
                    const Text('No history yet. Add a condition or allergy.'),
                  for (final h in list)
                    Card(
                      child: ListTile(
                        title: Text(h.title),
                        subtitle: Text(
                          '${h.kind}${h.detail.isEmpty ? '' : ' · ${h.detail}'}',
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _add(BuildContext context, TelehealthService tele) async {
    final title = TextEditingController();
    final detail = TextEditingController();
    try {
      var kind = 'condition';
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModal) => AlertDialog(
            title: const Text('History item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: kind,
                  items: const [
                    DropdownMenuItem(
                      value: 'condition',
                      child: Text('Condition'),
                    ),
                    DropdownMenuItem(value: 'allergy', child: Text('Allergy')),
                    DropdownMenuItem(value: 'surgery', child: Text('Surgery')),
                    DropdownMenuItem(
                      value: 'immunization',
                      child: Text('Immunization'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setModal(() => kind = v);
                  },
                ),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: detail,
                  decoration: const InputDecoration(labelText: 'Detail'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
      if (ok == true && title.text.trim().isNotEmpty) {
        await tele.addHistory(
          kind: kind,
          title: title.text,
          detail: detail.text,
        );
      }
    } finally {
      title.dispose();
      detail.dispose();
    }
  }
}

class HealthDataScreen extends StatelessWidget {
  const HealthDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tele = TelehealthService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Health data',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _log(context, tele),
        icon: const Icon(Icons.add),
        label: const Text('Log check-in'),
      ),
      body: StreamBuilder<List<HealthVital>>(
        stream: tele.watchVitals(),
        builder: (context, snap) {
          final list = snap.data ?? const <HealthVital>[];
          if (list.isEmpty) {
            return const Center(child: Text('No vitals yet. Log a check-in.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final v = list[i];
              return Card(
                child: ListTile(
                  title: Text(
                    '${v.hrLabel} · BP ${v.bpLabel}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${v.weightLabel} · ${v.sleepLabel}'
                    '${v.note.isEmpty ? '' : '\n${v.note}'}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _log(BuildContext context, TelehealthService tele) async {
    final hr = TextEditingController(text: '72');
    final sys = TextEditingController(text: '120');
    final dia = TextEditingController(text: '80');
    final wt = TextEditingController(text: '68');
    final sleep = TextEditingController(text: '7.2');
    final note = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Health check-in'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: hr,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Heart rate'),
                ),
                TextField(
                  controller: sys,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Systolic'),
                ),
                TextField(
                  controller: dia,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Diastolic'),
                ),
                TextField(
                  controller: wt,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Weight kg'),
                ),
                TextField(
                  controller: sleep,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sleep hours'),
                ),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (ok == true) {
        await tele.addVital(
          heartRate: int.tryParse(hr.text) ?? 72,
          systolic: int.tryParse(sys.text) ?? 120,
          diastolic: int.tryParse(dia.text) ?? 80,
          weightKg: double.tryParse(wt.text) ?? 68,
          sleepHours: double.tryParse(sleep.text) ?? 7,
          note: note.text,
        );
      }
    } finally {
      hr.dispose();
      sys.dispose();
      dia.dispose();
      wt.dispose();
      sleep.dispose();
      note.dispose();
    }
  }
}

class PrescriptionsScreen extends StatelessWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tele = TelehealthService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Prescriptions',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, tele),
        icon: const Icon(Icons.medication_outlined),
        label: const Text('Add'),
      ),
      body: StreamBuilder<List<Prescription>>(
        stream: tele.watchPrescriptions(),
        builder: (context, snap) {
          final list = snap.data ?? const <Prescription>[];
          if (list.isEmpty) {
            return const Center(child: Text('No prescriptions yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = list[i];
              return Card(
                child: SwitchListTile(
                  value: p.active,
                  onChanged: (v) => tele.setPrescriptionActive(p.id, v),
                  title: Text(
                    p.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text('${p.dose} · ${p.frequency}\n${p.prescriber}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _add(BuildContext context, TelehealthService tele) async {
    final name = TextEditingController();
    final dose = TextEditingController();
    final freq = TextEditingController(text: 'Once daily');
    final who = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Prescription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Medicine'),
              ),
              TextField(
                controller: dose,
                decoration: const InputDecoration(labelText: 'Dose'),
              ),
              TextField(
                controller: freq,
                decoration: const InputDecoration(labelText: 'Frequency'),
              ),
              TextField(
                controller: who,
                decoration: const InputDecoration(labelText: 'Prescriber'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (ok == true && name.text.trim().isNotEmpty) {
        await tele.addPrescription(
          name: name.text,
          dose: dose.text,
          frequency: freq.text,
          prescriber: who.text,
        );
      }
    } finally {
      name.dispose();
      dose.dispose();
      freq.dispose();
      who.dispose();
    }
  }
}

class MedicalDocumentsScreen extends StatelessWidget {
  const MedicalDocumentsScreen({super.key, this.kind});

  final String? kind;

  @override
  Widget build(BuildContext context) {
    final tele = TelehealthService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          kind == 'insurance' ? 'Insurance' : 'Medical documents',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, tele),
        icon: const Icon(Icons.upload_file_outlined),
        label: const Text('Add'),
      ),
      body: StreamBuilder<List<MedicalDocument>>(
        stream: tele.watchDocuments(kind: kind),
        builder: (context, snap) {
          final list = snap.data ?? const <MedicalDocument>[];
          if (list.isEmpty) {
            return const Center(child: Text('No documents yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = list[i];
              return Card(
                child: ListTile(
                  leading: d.isImage && d.hasFile
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: DecodedNetworkImage(
                            d.fileUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.image_outlined),
                          ),
                        )
                      : Icon(
                          d.hasFile
                              ? Icons.picture_as_pdf_outlined
                              : Icons.description_outlined,
                        ),
                  title: Text(d.title),
                  subtitle: Text(
                    [
                      d.kind,
                      if (d.fileName.isNotEmpty) d.fileName,
                      if (d.detail.isNotEmpty) d.detail,
                    ].join(' · '),
                  ),
                  onTap: d.hasFile ? () => _openDoc(context, d) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openDoc(BuildContext context, MedicalDocument doc) async {
    if (doc.isImage) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          child: InteractiveViewer(child: DecodedNetworkImage(doc.fileUrl)),
        ),
      );
      return;
    }
    final uri = Uri.parse(doc.fileUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _add(BuildContext context, TelehealthService tele) async {
    final title = TextEditingController();
    final detail = TextEditingController();
    try {
      var kind = this.kind ?? 'lab';
      PlatformFile? picked;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModal) => AlertDialog(
            title: const Text('Upload document'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: kind,
                    items: const [
                      DropdownMenuItem(value: 'lab', child: Text('Lab test')),
                      DropdownMenuItem(
                        value: 'scan',
                        child: Text('Scan / imaging'),
                      ),
                      DropdownMenuItem(
                        value: 'insurance',
                        child: Text('Insurance'),
                      ),
                      DropdownMenuItem(
                        value: 'visit',
                        child: Text('Visit summary'),
                      ),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModal(() => kind = v);
                    },
                  ),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: detail,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: const [
                          'pdf',
                          'jpg',
                          'jpeg',
                          'png',
                          'webp',
                          'heic',
                        ],
                      );
                      if (result.isEmpty) return;
                      setModal(() => picked = result.first);
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      picked == null ? 'Choose photo or PDF' : picked!.name,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
      if (ok != true) return;
      try {
        final file = picked;
        if (file != null) {
          final bytes = await file.readAsBytes();
          final ext = file.name.split('.').last.toLowerCase();
          await tele.uploadDocument(
            title: title.text,
            kind: kind,
            detail: detail.text,
            fileName: file.name,
            contentType: switch (ext) {
              'pdf' => 'application/pdf',
              'png' => 'image/png',
              'webp' => 'image/webp',
              'heic' => 'image/heic',
              _ => 'image/jpeg',
            },
            bytes: bytes,
          );
        } else if (title.text.trim().isNotEmpty) {
          await tele.addDocument(
            title: title.text,
            kind: kind,
            detail: detail.text,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    } finally {
      title.dispose();
      detail.dispose();
    }
  }
}

class DoctorNotesScreen extends StatelessWidget {
  const DoctorNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tele = TelehealthService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Doctor notes',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, tele),
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Add note'),
      ),
      body: StreamBuilder<List<DoctorNote>>(
        stream: tele.watchNotes(),
        builder: (context, snap) {
          final list = snap.data ?? const <DoctorNote>[];
          if (list.isEmpty) {
            return const Center(child: Text('No doctor notes yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final n = list[i];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: Text(n.author),
                subtitle: Text(n.body),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _add(BuildContext context, TelehealthService tele) async {
    final body = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Doctor note'),
          content: TextField(
            controller: body,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Visit recommendation'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (ok == true && body.text.trim().isNotEmpty) {
        final profile = await AuthService().getCurrentProfile();
        await tele.addNote(
          author: profile?.displayName ?? 'You',
          body: body.text,
        );
      }
    } finally {
      body.dispose();
    }
  }
}

class MedRemindersScreen extends StatelessWidget {
  const MedRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tele = TelehealthService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Reminders',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsInboxScreen(),
              ),
            ),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, tele),
        icon: const Icon(Icons.alarm_add_outlined),
        label: const Text('Add'),
      ),
      body: StreamBuilder<List<MedReminder>>(
        stream: tele.watchReminders(),
        builder: (context, snap) {
          final list = snap.data ?? const <MedReminder>[];
          if (list.isEmpty) {
            return const Center(child: Text('No reminders yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = list[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.alarm_rounded),
                  title: Text(r.title),
                  subtitle: Text('${r.whenLabel} · ${r.kind}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _add(BuildContext context, TelehealthService tele) async {
    final title = TextEditingController(text: 'Take medication');
    var time = const TimeOfDay(hour: 8, minute: 0);
    String labelFor(TimeOfDay t) {
      final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final m = t.minute.toString().padLeft(2, '0');
      final p = t.period == DayPeriod.pm ? 'PM' : 'AM';
      return 'Daily, $h:$m $p';
    }

    final when = TextEditingController(text: labelFor(time));
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModal) => AlertDialog(
            title: const Text('Reminder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: when,
                  decoration: const InputDecoration(labelText: 'When'),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: time,
                      );
                      if (picked == null) return;
                      setModal(() {
                        time = picked;
                        when.text = labelFor(picked);
                      });
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Pick time'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
      if (ok == true) {
        await tele.addReminder(
          title: title.text,
          whenLabel: when.text,
          hour: time.hour,
          minute: time.minute,
        );
      }
    } finally {
      title.dispose();
      when.dispose();
    }
  }
}

class InsuranceDetailsScreen extends StatelessWidget {
  const InsuranceDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tele = TelehealthService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Insurance details',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<UserProfile?>(
        stream: AuthService().watchCurrentProfile(),
        builder: (context, snap) {
          final p = snap.data;
          final ins = (p?.healthcare['insurance'] as String?) ?? '';
          final member = (p?.healthcare['insuranceMemberId'] as String?) ?? '';
          final plan = (p?.healthcare['insurancePlan'] as String?) ?? '';
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                child: ListTile(
                  title: Text(ins.isEmpty ? 'No insurer on file' : ins),
                  subtitle: Text(
                    [
                      if (plan.isNotEmpty) plan,
                      if (member.isNotEmpty) 'Member $member',
                    ].join(' · '),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _edit(context, tele, ins, member, plan),
                child: const Text('Update insurance'),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const MedicalDocumentsScreen(kind: 'insurance'),
                  ),
                ),
                child: const Text('Insurance documents'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    TelehealthService tele,
    String ins,
    String member,
    String plan,
  ) async {
    final p = TextEditingController(text: ins);
    final m = TextEditingController(text: member);
    final pl = TextEditingController(text: plan);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insurance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: p,
              decoration: const InputDecoration(labelText: 'Provider'),
            ),
            TextField(
              controller: pl,
              decoration: const InputDecoration(labelText: 'Plan'),
            ),
            TextField(
              controller: m,
              decoration: const InputDecoration(labelText: 'Member ID'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await tele.saveInsurance(
        provider: p.text,
        memberId: m.text,
        plan: pl.text,
      );
    }
  }
}

class InstantConsultSheet extends StatefulWidget {
  const InstantConsultSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const InstantConsultSheet(),
    );
  }

  @override
  State<InstantConsultSheet> createState() => _InstantConsultSheetState();
}

class _InstantConsultSheetState extends State<InstantConsultSheet> {
  final _providers = ProvidersService();
  final _care = HealthcareService();
  String _mode = 'video';
  bool _busy = false;
  bool _payNow = true;

  Future<void> _start(ServiceProvider d) async {
    setState(() => _busy = true);
    // Resolved up front because this sheet's context is gone once it pops.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final id = await _care.book(
        provider: d,
        startAt: DateTime.now().add(const Duration(minutes: 2)),
        mode: _mode,
        notes: 'Instant $_mode consult',
        payNow: _payNow,
      );
      final a = await _care.getAppointment(id);
      if (!mounted) return;
      navigator.pop();
      if (a == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Consult booked, but the room would not open. '
              'Start it from Appointments.',
            ),
          ),
        );
        return;
      }
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => SessionRoomScreen(appointment: a),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: StreamBuilder<List<ServiceProvider>>(
        stream: _providers.watchProviders(),
        builder: (context, snap) {
          final doctors = _providers.filter(
            snap.data ?? const [],
            category: 'Healthcare',
            availableNowOnly: true,
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Online consultation',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Video, audio, or chat with a doctor who is available now.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    final nav = Navigator.of(context);
                    nav.pop();
                    JoinVisitSheet.show(nav.context);
                  },
                  child: const Text('Join with a visit code'),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pay now (sandbox)'),
                subtitle: const Text('Test gateway · no card stored'),
                value: _payNow,
                onChanged: (v) => setState(() => _payNow = v),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in [
                    ('video', 'Video'),
                    ('audio', 'Audio'),
                    ('chat', 'Chat'),
                  ])
                    ChoiceChip(
                      label: Text(m.$2),
                      selected: _mode == m.$1,
                      onSelected: (_) => setState(() => _mode = m.$1),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (doctors.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text('No doctors available now. Book a slot instead.'),
                )
              else
                for (final d in doctors.take(4))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: d.photoUrl.isEmpty
                          ? null
                          : NetworkImage(d.photoUrl),
                      child: d.photoUrl.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(d.name),
                    subtitle: Text(
                      '${d.specialty} · ${d.priceLabel} · Available now',
                    ),
                    trailing: TextButton(
                      onPressed: _busy ? null : () => _start(d),
                      child: Text(_payNow ? 'Pay & join' : 'Join'),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class JoinVisitSheet extends StatefulWidget {
  const JoinVisitSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const JoinVisitSheet(),
    );
  }

  @override
  State<JoinVisitSheet> createState() => _JoinVisitSheetState();
}

class _JoinVisitSheetState extends State<JoinVisitSheet> {
  final _code = TextEditingController();
  final _care = HealthcareService();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    // Resolved up front because this sheet's context is gone once it pops.
    final navigator = Navigator.of(context);
    try {
      final a = await _care.appointmentFromJoinCode(_code.text);
      if (!mounted) return;
      if (a == null) {
        setState(() {
          _busy = false;
          _error = 'No visit found for that code.';
        });
        return;
      }
      navigator.pop();
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => SessionRoomScreen(appointment: a),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Join a live visit',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Enter the 6-character code from the patient’s session.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Visit code',
              hintText: 'AB3K7P',
            ),
            onSubmitted: (_) => _join(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.sos)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _join,
              child: Text(_busy ? 'Joining…' : 'Join visit'),
            ),
          ),
        ],
      ),
    );
  }
}
