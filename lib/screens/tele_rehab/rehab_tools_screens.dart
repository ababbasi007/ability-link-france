import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/rehab.dart';
import '../../services/auth_service.dart';
import '../../services/rehab_service.dart';
import '../../theme/app_colors.dart';
import '../notifications/notifications_inbox_screen.dart';

class RehabProgressScreen extends StatelessWidget {
  const RehabProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rehab = RehabService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Progress & goals',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Therapist notes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const RehabNotesScreen()),
            ),
            icon: const Icon(Icons.notes_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addGoal(context, rehab),
        label: const Text('Add goal'),
        icon: const Icon(Icons.flag_outlined),
      ),
      body: StreamBuilder<List<RehabLog>>(
        stream: rehab.watchLogs(),
        builder: (context, logSnap) {
          final logs = logSnap.data ?? const <RehabLog>[];
          final bars = rehab.weekBars(logs);
          return StreamBuilder<List<RehabGoal>>(
            stream: rehab.watchGoals(),
            builder: (context, goalSnap) {
              final goals = goalSnap.data ?? const <RehabGoal>[];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                children: [
                  Text(
                    'This week · streak ${rehab.streak(logs)} days · ${rehab.consistency(logs)}% consistency',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < bars.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: FractionallySizedBox(
                                      heightFactor: bars[i],
                                      widthFactor: 1,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Rehabilitation goals',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final g in goals)
                    Card(
                      child: ListTile(
                        title: Text(g.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.target),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: g.progress / 100,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        trailing: Text('${g.progress}%'),
                        onTap: () => rehab.setGoalProgress(
                          g.id,
                          (g.progress + 10).clamp(0, 100),
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

  Future<void> _addGoal(BuildContext context, RehabService rehab) async {
    final title = TextEditingController();
    final target = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('New goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Goal'),
              ),
              TextField(
                controller: target,
                decoration: const InputDecoration(labelText: 'Target / date'),
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
      if (ok == true && title.text.trim().isNotEmpty) {
        await rehab.addGoal(title: title.text, target: target.text);
      }
    } finally {
      title.dispose();
      target.dispose();
    }
  }
}

class RehabHealthScreen extends StatelessWidget {
  const RehabHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rehab = RehabService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Health & recovery data',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _log(context, rehab),
        icon: const Icon(Icons.add),
        label: const Text('Log today'),
      ),
      body: StreamBuilder<List<RehabHealthEntry>>(
        stream: rehab.watchHealth(),
        builder: (context, snap) {
          final list = snap.data ?? const <RehabHealthEntry>[];
          if (list.isEmpty) {
            return const Center(child: Text('No recovery logs yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = list[i];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: Text(
                  'Pain ${e.pain}/10 · Energy ${e.energy}/10 · Mobility ${e.mobility}/10',
                ),
                subtitle: Text(
                  '${e.createdAt.day}/${e.createdAt.month} · ${e.note.isEmpty ? 'No note' : e.note}',
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _log(BuildContext context, RehabService rehab) async {
    var pain = 3;
    var energy = 6;
    var mobility = 6;
    final note = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModal) => AlertDialog(
            title: const Text('Recovery check-in'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pain $pain'),
                Slider(
                  value: pain.toDouble(),
                  max: 10,
                  divisions: 10,
                  onChanged: (v) => setModal(() => pain = v.round()),
                ),
                Text('Energy $energy'),
                Slider(
                  value: energy.toDouble(),
                  max: 10,
                  divisions: 10,
                  onChanged: (v) => setModal(() => energy = v.round()),
                ),
                Text('Mobility $mobility'),
                Slider(
                  value: mobility.toDouble(),
                  max: 10,
                  divisions: 10,
                  onChanged: (v) => setModal(() => mobility = v.round()),
                ),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Note'),
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
        await rehab.addHealth(
          pain: pain,
          energy: energy,
          mobility: mobility,
          note: note.text,
        );
      }
    } finally {
      note.dispose();
    }
  }
}

class RehabRemindersScreen extends StatelessWidget {
  const RehabRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rehab = RehabService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Appointment reminders',
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
            icon: const Icon(Icons.inbox_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, rehab),
        icon: const Icon(Icons.alarm_add_outlined),
        label: const Text('Add reminder'),
      ),
      body: StreamBuilder<List<RehabReminder>>(
        stream: rehab.watchReminders(),
        builder: (context, snap) {
          final list = snap.data ?? const <RehabReminder>[];
          if (list.isEmpty) {
            return const Center(child: Text('No reminders yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = list[i];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Icon(
                  r.kind == 'session'
                      ? Icons.videocam_outlined
                      : Icons.fitness_center_outlined,
                  color: AppColors.primary,
                ),
                title: Text(r.title),
                subtitle: Text(r.whenLabel),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _add(BuildContext context, RehabService rehab) async {
    final title = TextEditingController(text: 'Therapy session');
    var time = const TimeOfDay(hour: 11, minute: 0);
    var kind = 'session';
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
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: kind,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'session',
                      child: Text('Rehab session'),
                    ),
                    DropdownMenuItem(
                      value: 'exercise',
                      child: Text('Exercise'),
                    ),
                  ],
                  onChanged: (v) => setModal(() => kind = v ?? 'session'),
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
        await rehab.addReminder(
          title: title.text,
          whenLabel: when.text,
          kind: kind,
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

class RehabNotesScreen extends StatelessWidget {
  const RehabNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rehab = RehabService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Session notes',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, rehab),
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Add note'),
      ),
      body: StreamBuilder<List<RehabNote>>(
        stream: rehab.watchNotes(),
        builder: (context, snap) {
          final list = snap.data ?? const <RehabNote>[];
          if (list.isEmpty) {
            // These notes live under the patient's own document and only the
            // owner can write them, so the copy must not imply the therapist
            // posts here.
            return const Center(
              child: Text(
                'No notes yet. Save what your therapist recommended.',
              ),
            );
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

  Future<void> _add(BuildContext context, RehabService rehab) async {
    final body = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Session note'),
          content: TextField(
            controller: body,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'What did the therapist recommend?',
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
      if (ok == true && body.text.trim().isNotEmpty) {
        final profile = await AuthService().getCurrentProfile();
        await rehab.addNote(
          author: profile?.displayName ?? 'You',
          body: body.text,
        );
      }
    } finally {
      body.dispose();
    }
  }
}

class TherapistChatScreen extends StatefulWidget {
  const TherapistChatScreen({
    super.key,
    required this.threadId,
    required this.title,
    this.appointmentId = '',
  });

  final String threadId;
  final String title;

  /// Set for visit threads so the clinician on the other device can join.
  final String appointmentId;

  @override
  State<TherapistChatScreen> createState() => _TherapistChatScreenState();
}

class _TherapistChatScreenState extends State<TherapistChatScreen> {
  final _rehab = RehabService();
  final _input = TextEditingController();
  late final Future<void> _ready = _rehab.ensureChatThread(
    widget.threadId,
    appointmentId: widget.appointmentId,
  );

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    final profile = await AuthService().getCurrentProfile();
    await _rehab.sendChat(
      threadId: widget.threadId,
      body: text,
      author: profile?.firstName ?? 'You',
      appointmentId: widget.appointmentId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _ready,
              builder: (context, ready) {
                if (ready.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return StreamBuilder<List<SessionChatMessage>>(
                  stream: _rehab.watchChat(widget.threadId),
                  builder: (context, snap) {
                    final list = snap.data ?? const <SessionChatMessage>[];
                    if (list.isEmpty) {
                      return const Center(
                        child: Text('Message your therapist here.'),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final m = list[i];
                        final mine = m.uid == _rehab.uid;
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: mine
                                  ? AppColors.primary
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              m.body,
                              style: TextStyle(
                                color: mine ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(
                        hintText: 'Message…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Send message',
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                    color: AppColors.primary,
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
