import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/care_appointment.dart';
import '../../services/background_task.dart';
import '../../services/calendar_sync_service.dart';
import '../../services/healthcare_service.dart';
import '../../theme/app_colors.dart';
import '../providers/provider_profile_screen.dart';
import 'session_room_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, this.kind});

  final String? kind;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _care = HealthcareService();

  @override
  void initState() {
    super.initState();
    runInBackground(_care.ensureDemoAppointments(), 'seed appointments');
  }

  void _open(CareAppointment a) {
    if (a.isRemote && a.status == 'booked') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SessionRoomScreen(appointment: a),
        ),
      );
      return;
    }
    if (a.providerId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProviderProfileScreen(providerId: a.providerId),
        ),
      );
    }
  }

  Future<void> _reschedule(CareAppointment a) async {
    final date = await showDatePicker(
      context: context,
      initialDate: a.startAt.isAfter(DateTime.now())
          ? a.startAt
          : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(a.startAt),
    );
    if (time == null) return;
    await _care.reschedule(
      a.id,
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Appointment rescheduled.')));
  }

  Future<void> _followUp(CareAppointment a) async {
    await _care.bookFollowUp(a);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Follow-up booked in 2 weeks.')),
    );
  }

  Future<void> _addToCalendar(CareAppointment a) async {
    try {
      final ok = await CalendarSyncService.instance.addAppointment(a);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Added to your device calendar.'
                : 'Could not open the calendar app.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calendar sync failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.kind == 'rehab' ? 'Rehab sessions' : 'Appointments',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<CareAppointment>>(
        stream: _care.watchAppointments(kind: widget.kind),
        builder: (context, snap) {
          final all = snap.data ?? const <CareAppointment>[];
          final upcoming = all.where((a) => a.isUpcoming).toList();
          final past = all.where((a) => !a.isUpcoming).toList()
            ..sort((a, b) => b.startAt.compareTo(a.startAt));

          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (all.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/empty_states/empty_appointments.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No appointments yet. Book from a provider profile.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (upcoming.isNotEmpty) ...[
                Text(
                  'Upcoming',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                for (final a in upcoming)
                  _ApptTile(
                    appointment: a,
                    onOpen: () => _open(a),
                    onCancel: () => _care.cancel(a.id),
                    onReschedule: () => _reschedule(a),
                    onAddToCalendar: () => _addToCalendar(a),
                  ),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Past',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                for (final a in past)
                  _ApptTile(
                    appointment: a,
                    onOpen: () => _open(a),
                    onFollowUp: a.status == 'completed'
                        ? () => _followUp(a)
                        : null,
                    onAddToCalendar: () => _addToCalendar(a),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ApptTile extends StatelessWidget {
  const _ApptTile({
    required this.appointment,
    required this.onOpen,
    this.onCancel,
    this.onReschedule,
    this.onFollowUp,
    this.onAddToCalendar,
  });

  final CareAppointment appointment;
  final VoidCallback onOpen;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;
  final VoidCallback? onFollowUp;
  final VoidCallback? onAddToCalendar;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          ListTile(
            onTap: onOpen,
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              backgroundImage: a.photoUrl.isEmpty
                  ? null
                  : NetworkImage(a.photoUrl),
              child: a.photoUrl.isEmpty
                  ? const Icon(Icons.event, color: AppColors.primary)
                  : null,
            ),
            title: Text(
              a.providerName,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${a.specialty} · ${a.whenLabel}\n${a.modeLabel} · ${a.status}'
              '${a.summary.isEmpty ? '' : '\n${a.summary}'}'
              '${a.followUpOf.isEmpty ? '' : '\nFollow-up visit'}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
          ),
          if (onCancel != null ||
              onReschedule != null ||
              onFollowUp != null ||
              onAddToCalendar != null)
            OverflowBar(
              children: [
                if (onAddToCalendar != null)
                  TextButton.icon(
                    onPressed: onAddToCalendar,
                    icon: const Icon(Icons.event_available_rounded, size: 18),
                    label: const Text('Calendar'),
                  ),
                if (onReschedule != null)
                  TextButton(
                    onPressed: onReschedule,
                    child: const Text('Reschedule'),
                  ),
                if (onCancel != null)
                  TextButton(onPressed: onCancel, child: const Text('Cancel')),
                if (onFollowUp != null)
                  TextButton(
                    onPressed: onFollowUp,
                    child: const Text('Book follow-up'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
