import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/care_circle.dart';
import '../../models/service_provider.dart';
import '../../services/care_circle_service.dart';
import '../../services/healthcare_service.dart';
import '../../services/providers_service.dart';
import '../../theme/app_colors.dart';
import '../assistance/assistance_marketplace_screen.dart';
import '../healthcare/appointments_screen.dart';
import '../healthcare/session_room_screen.dart';
import '../providers/provider_profile_screen.dart';
import '../telehealth/telehealth_records_screens.dart';

String _shortWhen(DateTime d) {
  final local = d.toLocal();
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final m = local.minute.toString().padLeft(2, '0');
  final am = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.month}/${local.day} $h:$m $am';
}

void openFindCaregivers(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const AssistanceMarketplaceScreen(
        title: 'Find Caregivers',
        initialTypeId: 'personal_assistant',
      ),
    ),
  );
}

Future<void> showCareHireSheet(
  BuildContext context, {
  required ServiceProvider provider,
}) async {
  final care = CareCircleService();
  final providers = ProvidersService();
  final serviceCtrl = TextEditingController(
    text: provider.services.isNotEmpty
        ? provider.services.first
        : 'Personal assistance',
  );
  final scheduleCtrl = TextEditingController(
    text: provider.availabilitySlots.isNotEmpty
        ? provider.availabilitySlots.first
        : 'Weekdays mornings',
  );
  final notesCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  var submitting = false;
  var payNow = true;

  try {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Hire ${provider.name}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Request personal assistance with schedule and needs. '
                      'You can also book a visit after.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: serviceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Service',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: scheduleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Preferred schedule',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesCtrl,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Care needs / notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pay now (sandbox)'),
                      subtitle: Text(
                        'Test gateway · ${provider.priceLabel} · no card stored',
                      ),
                      value: payNow,
                      onChanged: (v) => setModal(() => payNow = v),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              setModal(() => submitting = true);
                              try {
                                await care.submitHireRequest(
                                  providerId: provider.id,
                                  providerName: provider.name,
                                  service: serviceCtrl.text.trim(),
                                  scheduleLabel: scheduleCtrl.text.trim(),
                                  notes: notesCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  ownerUid: provider.ownerUid,
                                  payNow: payNow,
                                  amountCents:
                                      (provider.priceFrom <= 0
                                          ? 25
                                          : provider.priceFrom) *
                                      100,
                                );
                                await providers.submitEnquiry(
                                  ProviderEnquiry(
                                    providerId: provider.id,
                                    providerName: provider.name,
                                    service: serviceCtrl.text.trim(),
                                    preferredSlot: scheduleCtrl.text.trim(),
                                    contactPhone: phoneCtrl.text.trim(),
                                    message: notesCtrl.text.trim().isEmpty
                                        ? 'Hire request from Caregiver Hub'
                                        : notesCtrl.text.trim(),
                                  ),
                                );
                                if (ctx.mounted) Navigator.pop(ctx, true);
                              } catch (e) {
                                setModal(() => submitting = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(
                                    ctx,
                                  ).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(
                        submitting
                            ? 'Sending…'
                            : (payNow
                                  ? 'Hire & pay ${provider.priceLabel}'
                                  : 'Send hire request'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            payNow
                ? 'Hire requested and paid (sandbox).'
                : 'Hire request sent.',
          ),
        ),
      );
    }
  } finally {
    serviceCtrl.dispose();
    scheduleCtrl.dispose();
    notesCtrl.dispose();
    phoneCtrl.dispose();
  }
}

// ─── Schedule ────────────────────────────────────────────────────────────────

class CareScheduleScreen extends StatefulWidget {
  const CareScheduleScreen({super.key});

  @override
  State<CareScheduleScreen> createState() => _CareScheduleScreenState();
}

class _CareScheduleScreenState extends State<CareScheduleScreen> {
  final _care = CareCircleService();

  Future<void> _addTask() async {
    final title = TextEditingController();
    final person = TextEditingController();
    final time = TextEditingController(text: '09:00 AM');
    var kind = 'task';
    final notes = TextEditingController();
    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModal) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  20 + MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Add care task',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: title,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: person,
                        decoration: const InputDecoration(
                          labelText: 'For (person)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: time,
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: kind,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'task', child: Text('Task')),
                          DropdownMenuItem(
                            value: 'meds',
                            child: Text('Medication'),
                          ),
                          DropdownMenuItem(
                            value: 'appointment',
                            child: Text('Appointment'),
                          ),
                          DropdownMenuItem(
                            value: 'assistance',
                            child: Text('Personal assistance'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setModal(() => kind = v);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notes,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Save task'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
      if (ok != true || title.text.trim().isEmpty) return;
      await _care.addTask(
        title: title.text,
        personName: person.text,
        timeLabel: time.text,
        kind: kind,
        notes: notes.text,
      );
    } finally {
      title.dispose();
      person.dispose();
      time.dispose();
      notes.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Care schedule',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AppointmentsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Appointments',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add task'),
      ),
      body: StreamBuilder<List<CareTask>>(
        stream: _care.watchTasks(),
        builder: (context, snap) {
          final tasks = snap.data ?? const <CareTask>[];
          if (tasks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No tasks yet. Tap Add task to build today’s schedule.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = tasks[i];
              return Dismissible(
                key: ValueKey(t.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: const Color(0xFFEF4444),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => _care.deleteTask(t.id),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    onTap: () => _care.toggleTask(t),
                    leading: Icon(
                      t.isDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      color: t.isDone
                          ? const Color(0xFF22C55E)
                          : AppColors.primary,
                    ),
                    title: Text(
                      t.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        decoration: t.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      [
                        t.timeLabel,
                        if (t.personName.isNotEmpty) t.personName,
                        t.kind,
                        if (t.notes.isNotEmpty) t.notes,
                      ].join(' · '),
                      style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Notes ───────────────────────────────────────────────────────────────────

class CareNotesScreen extends StatefulWidget {
  const CareNotesScreen({super.key});

  @override
  State<CareNotesScreen> createState() => _CareNotesScreenState();
}

class _CareNotesScreenState extends State<CareNotesScreen> {
  final _care = CareCircleService();

  Future<void> _add() async {
    final title = TextEditingController();
    final body = TextEditingController();
    final person = TextEditingController();
    var kind = 'general';
    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModal) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  20 + MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'New care note',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: person,
                      decoration: const InputDecoration(
                        labelText: 'About (person)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: kind,
                      decoration: const InputDecoration(
                        labelText: 'Kind',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'general',
                          child: Text('General'),
                        ),
                        DropdownMenuItem(value: 'meds', child: Text('Meds')),
                        DropdownMenuItem(value: 'visit', child: Text('Visit')),
                        DropdownMenuItem(
                          value: 'incident',
                          child: Text('Incident'),
                        ),
                        DropdownMenuItem(
                          value: 'assistance',
                          child: Text('Assistance'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setModal(() => kind = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: body,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: const Text('Save note'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
      if (ok != true || title.text.trim().isEmpty || body.text.trim().isEmpty) {
        return;
      }
      await _care.addNote(
        title: title.text,
        body: body.text,
        personName: person.text,
        kind: kind,
      );
    } finally {
      title.dispose();
      body.dispose();
      person.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Care notes',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.note_add_rounded, color: Colors.white),
      ),
      body: StreamBuilder<List<CareNote>>(
        stream: _care.watchNotes(),
        builder: (context, snap) {
          final notes = snap.data ?? const <CareNote>[];
          if (notes.isEmpty) {
            return Center(
              child: Text(
                'No care notes yet.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final n = notes[i];
              return Dismissible(
                key: ValueKey(n.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _care.deleteNote(n.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: const Color(0xFFEF4444),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF0F1F3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Text(
                            n.kind,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n.body,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.4,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          n.author,
                          if (n.personName.isNotEmpty) n.personName,
                          _shortWhen(n.createdAt),
                        ].join(' · '),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── History ─────────────────────────────────────────────────────────────────

class CareHistoryScreen extends StatelessWidget {
  const CareHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = CareCircleService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Care history',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<CareHistoryEvent>>(
        stream: care.watchHistory(),
        builder: (context, snap) {
          final events = snap.data ?? const <CareHistoryEvent>[];
          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'History will appear as you complete tasks and add notes.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = events[i];
              final icon = switch (e.kind) {
                'meds' => Icons.medication_rounded,
                'note' => Icons.sticky_note_2_outlined,
                'hire' => Icons.handshake_outlined,
                'appointment' => Icons.event_available_rounded,
                'message' => Icons.forum_outlined,
                _ => Icons.history_rounded,
              };
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  e.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${e.detail}\n${_shortWhen(e.createdAt)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Chat ────────────────────────────────────────────────────────────────────

class CareCircleChatScreen extends StatefulWidget {
  const CareCircleChatScreen({super.key});

  @override
  State<CareCircleChatScreen> createState() => _CareCircleChatScreenState();
}

class _CareCircleChatScreenState extends State<CareCircleChatScreen> {
  final _care = CareCircleService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    await _care.sendMessage(body: text);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Care circle chat',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CareMessage>>(
              stream: _care.watchMessages(),
              builder: (context, snap) {
                final messages = snap.data ?? const <CareMessage>[];
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final mine = m.uid.isNotEmpty && m.uid == _uid;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                        ),
                        decoration: BoxDecoration(
                          color: mine ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: mine
                              ? null
                              : Border.all(color: const Color(0xFFF0F1F3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!mine)
                              Text(
                                m.author,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            Text(
                              m.body,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: mine
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _shortWhen(m.createdAt),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: mine
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Message the care circle…',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Meds hub ────────────────────────────────────────────────────────────────

class CareMedsScreen extends StatelessWidget {
  const CareMedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = CareCircleService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Medication reminders',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MedRemindersScreen(),
                ),
              );
            },
            child: const Text('Full list'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const MedRemindersScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Add reminder'),
      ),
      body: StreamBuilder<List<CareTask>>(
        stream: care.watchTasks(),
        builder: (context, snap) {
          final meds = (snap.data ?? const <CareTask>[])
              .where((t) => t.kind == 'meds')
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Text(
                'Today’s medication tasks from your care schedule. '
                'Use Full list for persistent telehealth reminders.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              if (meds.isEmpty)
                Text(
                  'No meds tasks on today’s schedule.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                for (final t in meds)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => care.toggleTask(t),
                      leading: Icon(
                        t.isDone
                            ? Icons.check_circle
                            : Icons.medication_liquid_rounded,
                        color: t.isDone
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFF97316),
                      ),
                      title: Text(
                        t.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text('${t.timeLabel} · ${t.personName}'),
                      trailing: Text(
                        t.isDone ? 'Done' : 'Due',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: t.isDone
                              ? const Color(0xFF22C55E)
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Personal assistance + hires ─────────────────────────────────────────────

class CarePersonalAssistanceScreen extends StatelessWidget {
  const CarePersonalAssistanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = CareCircleService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Personal assistance',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          FilledButton.icon(
            onPressed: () => openFindCaregivers(context),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Find & hire caregivers'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const AssistanceMarketplaceScreen(title: 'Available now'),
                ),
              );
            },
            icon: const Icon(Icons.circle, size: 12, color: Color(0xFF22C55E)),
            label: const Text('Available caregivers now'),
          ),
          const SizedBox(height: 20),
          Text(
            'Your hire requests',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<CareHireRequest>>(
            stream: care.watchHires(),
            builder: (context, snap) {
              final hires = snap.data ?? const <CareHireRequest>[];
              if (hires.isEmpty) {
                return Text(
                  'No hire requests yet. Find a caregiver and tap Hire.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                  ),
                );
              }
              return Column(
                children: [
                  for (final h in hires)
                    Card(
                      child: ListTile(
                        title: Text(
                          h.providerName,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${h.service}\n${h.scheduleLabel} · ${h.status}'
                          '${h.paymentStatus == 'paid' ? ' · paid sandbox' : ''}',
                        ),
                        isThreeLine: true,
                        trailing: h.status == 'requested'
                            ? TextButton(
                                onPressed: () =>
                                    care.updateHireStatus(h.id, 'cancelled'),
                                child: const Text('Cancel'),
                              )
                            : null,
                        onTap: h.providerId.isEmpty
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ProviderProfileScreen(
                                      providerId: h.providerId,
                                    ),
                                  ),
                                );
                              },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Care video call ─────────────────────────────────────────────────────────

class CareVideoCallSheet extends StatefulWidget {
  const CareVideoCallSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CareVideoCallSheet(),
    );
  }

  @override
  State<CareVideoCallSheet> createState() => _CareVideoCallSheetState();
}

class _CareVideoCallSheetState extends State<CareVideoCallSheet> {
  final _providers = ProvidersService();
  final _care = HealthcareService();
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
        mode: 'video',
        notes: 'Care circle video check-in',
        payNow: _payNow,
      );
      final a = await _care.getAppointment(id);
      if (!mounted) return;
      navigator.pop();
      if (a == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Call booked, but the room would not open. '
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
          final caregivers = _providers.filter(
            snap.data ?? const [],
            category: 'Assistance',
            availableNowOnly: true,
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Video call a caregiver',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Starts a live video session with an available caregiver.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pay now (sandbox)'),
                value: _payNow,
                onChanged: (v) => setState(() => _payNow = v),
              ),
              const SizedBox(height: 12),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (caregivers.isEmpty)
                Text(
                  'No caregivers available right now. Browse the directory to book.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                for (final c in caregivers.take(6))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: c.photoUrl.isEmpty
                          ? null
                          : NetworkImage(c.photoUrl),
                      child: c.photoUrl.isEmpty
                          ? Text(c.name.isEmpty ? '?' : c.name[0])
                          : null,
                    ),
                    title: Text(
                      c.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${c.specialty} · ${c.verified ? 'Verified' : 'Pending'}',
                    ),
                    trailing: const Icon(Icons.videocam_rounded),
                    onTap: () => _start(c),
                  ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openFindCaregivers(context);
                },
                child: const Text('Browse all caregivers'),
              ),
            ],
          );
        },
      ),
    );
  }
}
