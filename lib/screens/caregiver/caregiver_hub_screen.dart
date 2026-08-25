import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/care_circle.dart';
import '../../models/emergency.dart';
import '../../services/auth_service.dart';
import '../../services/care_circle_service.dart';
import '../../services/emergency_service.dart';
import '../../theme/app_colors.dart';
import '../ai/ai_assistant_screen.dart';
import '../emergency/emergency_screen.dart';
import '../healthcare/appointments_screen.dart';
import '../privacy/passport_privacy_screen.dart';
import 'care_circle_screen.dart';
import 'caregiver_tools_screens.dart';

class CaregiverHubScreen extends StatefulWidget {
  const CaregiverHubScreen({super.key});

  @override
  State<CaregiverHubScreen> createState() => _CaregiverHubScreenState();
}

class _CaregiverHubScreenState extends State<CaregiverHubScreen> {
  final _care = CareCircleService();
  final _auth = AuthService();
  final _emergency = EmergencyService();

  @override
  void initState() {
    super.initState();
    _care.ensureSeeded();
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder(
          stream: _auth.watchCurrentProfile(),
          builder: (context, profileSnap) {
            return StreamBuilder<List<CareMember>>(
              stream: _care.watchMembers(),
              builder: (context, membersSnap) {
                return StreamBuilder<List<CareTask>>(
                  stream: _care.watchTasks(),
                  builder: (context, tasksSnap) {
                    return StreamBuilder<List<SosAlert>>(
                      stream: _emergency.watchMySos(),
                      builder: (context, sosSnap) {
                        final firstName =
                            profileSnap.data?.firstName ?? 'there';
                        final members =
                            membersSnap.data ?? const <CareMember>[];
                        final tasks = tasksSnap.data ?? const <CareTask>[];
                        final sos = sosSnap.data ?? const <SosAlert>[];
                        final pending = tasks.where((t) => !t.isDone).toList();
                        final openSos = sos
                            .where((s) => s.status == 'open')
                            .toList();
                        final alertCount = pending.length + openSos.length;

                        return Column(
                          children: [
                            _Header(
                              alertCount: alertCount,
                              onAlerts: () => _open(const EmergencyScreen()),
                            ),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  100,
                                ),
                                children: [
                                  _HeroCard(
                                    firstName: firstName,
                                    taskCount: pending.length,
                                    members: members,
                                    onManage: () =>
                                        _open(const CareCircleScreen()),
                                    onAdd: () =>
                                        _open(const CareCircleScreen()),
                                  ),
                                  const SizedBox(height: 14),
                                  _StatsRow(
                                    taskCount: tasks.length,
                                    medsDue: tasks
                                        .where(
                                          (t) => t.kind == 'meds' && !t.isDone,
                                        )
                                        .length,
                                    alertCount: alertCount,
                                    appointmentCount: tasks
                                        .where(
                                          (t) =>
                                              t.kind == 'appointment' &&
                                              !t.isDone,
                                        )
                                        .length,
                                    onTasks: () =>
                                        _open(const CareScheduleScreen()),
                                    onMeds: () => _open(const CareMedsScreen()),
                                    onAlerts: () =>
                                        _open(const EmergencyScreen()),
                                    onAppointments: () =>
                                        _open(const AppointmentsScreen()),
                                  ),
                                  const SizedBox(height: 20),
                                  _TodaysSchedule(
                                    tasks: tasks,
                                    onToggle: (t) => _care.toggleTask(t),
                                    onAdd: () =>
                                        _open(const CareScheduleScreen()),
                                    onViewAll: () =>
                                        _open(const CareScheduleScreen()),
                                  ),
                                  const SizedBox(height: 18),
                                  _HubModules(
                                    onFind: () => openFindCaregivers(context),
                                    onNotes: () =>
                                        _open(const CareNotesScreen()),
                                    onHistory: () =>
                                        _open(const CareHistoryScreen()),
                                    onAssistance: () => _open(
                                      const CarePersonalAssistanceScreen(),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _HealthAndAlerts(
                                    pending: pending,
                                    openSos: openSos,
                                    onAlerts: () =>
                                        _open(const EmergencyScreen()),
                                  ),
                                  const SizedBox(height: 20),
                                  _QuickActions(
                                    onMessage: () =>
                                        _open(const CareCircleChatScreen()),
                                    onVideo: () =>
                                        CareVideoCallSheet.show(context),
                                    onCarePlan: () =>
                                        _open(const CareNotesScreen()),
                                    onReports: () =>
                                        _open(const CareHistoryScreen()),
                                    onPassport: () =>
                                        _open(const PassportPrivacyScreen()),
                                    onEmergency: () =>
                                        _open(const EmergencyScreen()),
                                  ),
                                  const SizedBox(height: 16),
                                  _AssistantCard(
                                    onTips: () =>
                                        _open(const AiAssistantScreen()),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.alertCount, required this.onAlerts});

  final int alertCount;
  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF1E1B4B),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Caregiver Hub',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E2A5E),
                  ),
                ),
                Text(
                  'Support. Manage. Stay Connected.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Alerts',
                onPressed: onAlerts,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.primary,
                ),
              ),
              if (alertCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 15,
                    height: 15,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.badge,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      alertCount > 9 ? '9+' : '$alertCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Chat',
            onPressed: () {},
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.firstName,
    required this.taskCount,
    required this.members,
    required this.onManage,
    required this.onAdd,
  });

  final String firstName;
  final int taskCount;
  final List<CareMember> members;
  final VoidCallback onManage;
  final VoidCallback onAdd;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF5B52E8), Color(0xFF4F46C8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_greeting, $firstName 👋',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            taskCount == 0
                ? 'All tasks for today are done'
                : 'You have $taskCount task${taskCount == 1 ? '' : 's'} today',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFBBF24),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onManage,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Care Circle',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E1B4B),
                            ),
                          ),
                          Text(
                            '${members.length} Member${members.length == 1 ? '' : 's'}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'People in My Care',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final m in members.take(3))
                Expanded(
                  child: _CarePerson(
                    name: m.name,
                    relation: m.relation,
                    color: Color(m.colorValue),
                    initials: m.initials,
                  ),
                ),
              Expanded(child: _AddPerson(onTap: onAdd)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CarePerson extends StatelessWidget {
  const _CarePerson({
    required this.name,
    required this.relation,
    required this.color,
    required this.initials,
  });

  final String name;
  final String relation;
  final Color color;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          relation,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 8,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _AddPerson extends StatelessWidget {
  const _AddPerson({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CustomPaint(
              painter: _DashedCirclePainter(
                color: Colors.white.withValues(alpha: 0.75),
              ),
              child: const Center(
                child: Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add Person',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(' ', style: GoogleFonts.plusJakartaSans(fontSize: 8)),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashCount = 18;
    final radius = size.width / 2 - 1;
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < dashCount; i++) {
      if (i.isOdd) continue;
      final start = (i / dashCount) * 6.283185;
      final end = ((i + 0.7) / dashCount) * 6.283185;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        end - start,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Stats ───────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.taskCount,
    required this.medsDue,
    required this.alertCount,
    required this.appointmentCount,
    required this.onTasks,
    required this.onMeds,
    required this.onAlerts,
    required this.onAppointments,
  });

  final int taskCount;
  final int medsDue;
  final int alertCount;
  final int appointmentCount;
  final VoidCallback onTasks;
  final VoidCallback onMeds;
  final VoidCallback onAlerts;
  final VoidCallback onAppointments;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTasks,
              child: _StatCard(
                icon: Icons.assignment_outlined,
                iconColor: AppColors.primary,
                iconBg: const Color(0xFFEEF0FF),
                value: '$taskCount',
                label: "Today's Tasks",
                link: 'View All >',
                linkColor: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onMeds,
              child: _StatCard(
                icon: Icons.medical_services_outlined,
                iconColor: const Color(0xFF22C55E),
                iconBg: const Color(0xFFE8F8EF),
                value: '$medsDue',
                label: 'Medications',
                subLabel: 'Due Today',
                subLabelColor: const Color(0xFF22C55E),
                link: 'View Schedule >',
                linkColor: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onAlerts,
              child: _StatCard(
                icon: Icons.monitor_heart_outlined,
                iconColor: const Color(0xFFEF4444),
                iconBg: const Color(0xFFFEE2E2),
                value: '$alertCount',
                label: 'Health Alerts',
                link: 'View Alerts >',
                linkColor: const Color(0xFFEF4444),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onAppointments,
              child: _StatCard(
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF3B82F6),
                iconBg: const Color(0xFFE8F1FF),
                value: '$appointmentCount',
                label: 'Upcoming\nAppointment',
                link: 'View Calendar >',
                linkColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
    required this.link,
    required this.linkColor,
    this.subLabel,
    this.subLabelColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;
  final String link;
  final Color linkColor;
  final String? subLabel;
  final Color? subLabelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E1B4B),
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1B4B),
              height: 1.2,
            ),
          ),
          if (subLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              subLabel!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: subLabelColor,
              ),
            ),
          ],
          const Spacer(),
          const SizedBox(height: 6),
          Text(
            link,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: linkColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Today's Schedule ────────────────────────────────────────────────────────

class _TodaysSchedule extends StatelessWidget {
  const _TodaysSchedule({
    required this.tasks,
    required this.onToggle,
    required this.onAdd,
    required this.onViewAll,
  });

  final List<CareTask> tasks;
  final ValueChanged<CareTask> onToggle;
  final VoidCallback onAdd;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Today's Schedule",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
            ),
            TextButton(
              onPressed: onAdd,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Add',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'All',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          Text(
            'No tasks yet — tap Add to schedule care.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          )
        else
          for (var i = 0; i < tasks.length && i < 5; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _ScheduleRow(
              data: _scheduleFromTask(tasks[i]),
              onTap: () => onToggle(tasks[i]),
            ),
          ],
      ],
    );
  }
}

_ScheduleData _scheduleFromTask(CareTask task) {
  late IconData icon;
  late Color color;
  late Color bg;
  if (task.kind == 'meds') {
    icon = Icons.medication_rounded;
    color = const Color(0xFF22C55E);
    bg = const Color(0xFFE8F8EF);
  } else if (task.kind == 'appointment') {
    icon = Icons.event_available_rounded;
    color = const Color(0xFFF97316);
    bg = const Color(0xFFFFF1E8);
  } else if (task.kind == 'assistance') {
    icon = Icons.handshake_outlined;
    color = const Color(0xFF14B8A6);
    bg = const Color(0xFFE6FAF7);
  } else {
    icon = Icons.fitness_center_rounded;
    color = const Color(0xFF3B82F6);
    bg = const Color(0xFFE8F1FF);
  }
  final done = task.isDone;
  if (done) {
    return _ScheduleData(
      time: task.timeLabel,
      title: task.title,
      person: task.personName,
      status: 'Completed',
      statusColor: const Color(0xFF22C55E),
      statusBg: const Color(0xFFE8F8EF),
      icon: icon,
      iconColor: color,
      iconBg: bg,
      statusIcon: Icons.check_circle_rounded,
    );
  }
  return _ScheduleData(
    time: task.timeLabel,
    title: task.title,
    person: task.personName,
    status: 'Pending',
    statusColor: const Color(0xFF6C63FF),
    statusBg: const Color(0xFFEEF0FF),
    icon: icon,
    iconColor: color,
    iconBg: bg,
    statusIcon: Icons.hourglass_empty_rounded,
  );
}

class _ScheduleData {
  const _ScheduleData({
    required this.time,
    required this.title,
    required this.person,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.statusIcon,
  });

  final String time;
  final String title;
  final String person;
  final String status;
  final Color statusColor;
  final Color statusBg;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final IconData statusIcon;
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.data, required this.onTap});

  final _ScheduleData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 58,
                child: Text(
                  data.time,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: data.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, size: 18, color: data.iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    Text(
                      data.person,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: data.statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(data.statusIcon, size: 12, color: data.statusColor),
                    const SizedBox(width: 3),
                    Text(
                      data.status,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: data.statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Health Snapshot + Alerts ────────────────────────────────────────────────

class _HealthAndAlerts extends StatelessWidget {
  const _HealthAndAlerts({
    required this.pending,
    required this.openSos,
    required this.onAlerts,
  });

  final List<CareTask> pending;
  final List<SosAlert> openSos;
  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(child: _HealthSnapshotCard()),
          const SizedBox(width: 10),
          Expanded(
            child: _AlertsCard(
              pending: pending,
              openSos: openSos,
              onAlerts: onAlerts,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthSnapshotCard extends StatelessWidget {
  const _HealthSnapshotCard();

  static const _vitals = [
    (
      Icons.favorite_rounded,
      Color(0xFFEF4444),
      Color(0xFFFEE2E2),
      '120/80',
      'Blood Pressure',
      'Normal',
    ),
    (
      Icons.water_drop_rounded,
      Color(0xFF3B82F6),
      Color(0xFFE8F1FF),
      '110 mg/dL',
      'Blood Sugar',
      'Normal',
    ),
    (
      Icons.bedtime_rounded,
      Color(0xFF6C63FF),
      Color(0xFFEEF0FF),
      '7.2 hrs',
      'Sleep',
      'Good',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Health Snapshot',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
              ),
              Text(
                'View Details >',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _vitals.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _vitals[i].$3,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_vitals[i].$1, size: 14, color: _vitals[i].$2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _vitals[i].$4,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E1B4B),
                        ),
                      ),
                      Text(
                        _vitals[i].$5,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _vitals[i].$6,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({
    required this.pending,
    required this.openSos,
    required this.onAlerts,
  });

  final List<CareTask> pending;
  final List<SosAlert> openSos;
  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (final s in openSos.take(2)) {
      items.add(
        GestureDetector(
          onTap: onAlerts,
          child: _AlertItem(
            icon: Icons.sos_rounded,
            iconColor: const Color(0xFFEF4444),
            iconBg: const Color(0xFFFEE2E2),
            title: 'SOS is open',
            subtitle: s.message.isEmpty ? 'Tap to view Emergency' : s.message,
          ),
        ),
      );
    }
    for (final t in pending.take(2 - items.length)) {
      items.add(
        _AlertItem(
          icon: t.kind == 'meds'
              ? Icons.medication_rounded
              : Icons.assignment_outlined,
          iconColor: const Color(0xFFF97316),
          iconBg: const Color(0xFFFFF1E8),
          title: t.title,
          subtitle: '${t.personName} · ${t.timeLabel}',
        ),
      );
    }
    if (items.isEmpty) {
      items.add(
        const _AlertItem(
          icon: Icons.check_circle_outline,
          iconColor: Color(0xFF22C55E),
          iconBg: Color(0xFFE8F8EF),
          title: 'All clear',
          subtitle: 'No pending tasks or SOS',
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Alerts',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onAlerts,
                child: Text(
                  'View All >',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            items[i],
          ],
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  const _AlertItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B4B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    color: const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }
}

// ─── Hub modules ─────────────────────────────────────────────────────────────

class _HubModules extends StatelessWidget {
  const _HubModules({
    required this.onFind,
    required this.onNotes,
    required this.onHistory,
    required this.onAssistance,
  });

  final VoidCallback onFind;
  final VoidCallback onNotes;
  final VoidCallback onHistory;
  final VoidCallback onAssistance;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      (
        Icons.search_rounded,
        'Find caregivers',
        onFind,
        const Color(0xFF6C63FF),
      ),
      (
        Icons.sticky_note_2_outlined,
        'Care notes',
        onNotes,
        const Color(0xFFF97316),
      ),
      (
        Icons.history_rounded,
        'Care history',
        onHistory,
        const Color(0xFF3B82F6),
      ),
      (
        Icons.handshake_outlined,
        'Personal assistance',
        onAssistance,
        const Color(0xFF14B8A6),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Care tools',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.4,
          children: [
            for (final t in tiles)
              InkWell(
                onTap: t.$3,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF0F1F3)),
                  ),
                  child: Row(
                    children: [
                      Icon(t.$1, color: t.$4, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.$2,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Quick Actions ───────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onMessage,
    required this.onVideo,
    required this.onCarePlan,
    required this.onReports,
    required this.onPassport,
    required this.onEmergency,
  });

  final VoidCallback onMessage;
  final VoidCallback onVideo;
  final VoidCallback onCarePlan;
  final VoidCallback onReports;
  final VoidCallback onPassport;
  final VoidCallback onEmergency;

  static const _actions = [
    (
      Icons.chat_bubble_rounded,
      'Message Care\nCircle',
      Color(0xFF6C63FF),
      Color(0xFFEEF0FF),
    ),
    (
      Icons.videocam_rounded,
      'Video Call',
      Color(0xFF22C55E),
      Color(0xFFE8F8EF),
    ),
    (
      Icons.assignment_outlined,
      'Care Plan',
      Color(0xFFF97316),
      Color(0xFFFFF1E8),
    ),
    (
      Icons.description_outlined,
      'Health\nReports',
      Color(0xFF3B82F6),
      Color(0xFFE8F1FF),
    ),
    (Icons.badge_outlined, 'Passport', Color(0xFF8B5CF6), Color(0xFFF3E8FF)),
    (Icons.sos_rounded, 'Emergency\nSOS', Color(0xFFEF4444), Color(0xFFFEE2E2)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: switch (i) {
                      0 => onMessage,
                      1 => onVideo,
                      2 => onCarePlan,
                      3 => onReports,
                      4 => onPassport,
                      _ => onEmergency,
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _actions[i].$4,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              _actions[i].$1,
                              color: _actions[i].$3,
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _actions[i].$2,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E1B4B),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Caregiver Assistant ─────────────────────────────────────────────────────

class _AssistantCard extends StatelessWidget {
  const _AssistantCard({required this.onTips});

  final VoidCallback onTips;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/ai_robot.png',
            width: 52,
            height: 52,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Caregiver Assistant',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Remember to encourage light physical activity and a healthy diet.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onTips,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.white,
            ),
            child: Text(
              'View Tips',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
