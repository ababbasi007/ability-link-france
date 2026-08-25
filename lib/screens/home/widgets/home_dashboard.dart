import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/care_appointment.dart';
import '../../../models/user_profile.dart';
import '../../../theme/app_colors.dart';

const _navy = Color(0xFF1E1B4B);
const _muted = Color(0xFF6B7280);
const _shadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
];

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.onProfile,
    required this.onFavorites,
    required this.onBookings,
    required this.onReviews,
    required this.onReports,
    required this.onBookmarks,
  });

  final VoidCallback onProfile;
  final VoidCallback onFavorites;
  final VoidCallback onBookings;
  final VoidCallback onReviews;
  final VoidCallback onReports;
  final VoidCallback onBookmarks;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.person_rounded, AppColors.primary, 'My Profile', onProfile),
      (Icons.calendar_today_rounded, AppColors.primary, 'My Bookings', onBookings),
      (Icons.favorite_rounded, AppColors.primary, 'Favorites', onFavorites),
      (Icons.star_rounded, AppColors.primary, 'Reviews', onReviews),
      (Icons.bookmark_rounded, AppColors.primary, 'Saved', onBookmarks),
    ];
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.edit_square, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'Edit',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: items[i].$4,
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: items[i].$2.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(items[i].$1, color: items[i].$2, size: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        items[i].$3,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class HomeDashboardTrio extends StatelessWidget {
  const HomeDashboardTrio({
    super.key,
    required this.profile,
    required this.appointments,
    required this.onEditProfile,
    required this.onViewAllAppointments,
    required this.onAppointment,
    required this.onPassport,
  });

  final UserProfile? profile;
  final List<CareAppointment> appointments;
  final VoidCallback onEditProfile;
  final VoidCallback onViewAllAppointments;
  final ValueChanged<CareAppointment?> onAppointment;
  final VoidCallback onPassport;

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cardWidth = (c.maxWidth - _gap * 2) / 3;
        final compact = cardWidth < 150;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ProfileCard(
                profile: profile,
                onEdit: onEditProfile,
                compact: compact,
              ),
            ),
            const SizedBox(width: _gap),
            Expanded(
              child: _AppointmentsCard(
                appointments: appointments,
                onViewAll: onViewAllAppointments,
                onItem: onAppointment,
                compact: compact,
              ),
            ),
            const SizedBox(width: _gap),
            Expanded(
              child: _PassportCard(
                onView: onPassport,
                compact: compact,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child, this.compact = false});
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        boxShadow: _shadow,
      ),
      child: child,
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onEdit,
    this.compact = false,
  });
  final UserProfile? profile;
  final VoidCallback onEdit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final percent = profile == null
        ? 78
        : profile!.profileStrengthPercent.clamp(0, 100);
    final mobility = _mobilityLabel(profile);
    final comm = _communicationLabel(profile);
    final assist = (profile?.needCaregiver ?? true)
        ? 'Caregiver support'
        : 'Independent';

    return _WhiteCard(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Accessibility Profile',
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: compact ? 9 : 13,
              fontWeight: FontWeight.w800,
              color: _navy,
              height: 1.15,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          LayoutBuilder(
            builder: (context, inner) {
              final ringSize = compact ? 52.0 : 88.0;
              final ring = SizedBox(
                width: ringSize,
                height: ringSize,
                child: CustomPaint(
                  painter: _RingPainter(
                    percent / 100,
                    strokeWidth: compact ? 5 : 8,
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 4 : 10,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$percent%',
                              style: GoogleFonts.inter(
                                fontSize: compact ? 13 : 18,
                                fontWeight: FontWeight.w800,
                                color: _navy,
                                height: 1,
                              ),
                            ),
                            SizedBox(height: compact ? 1 : 2),
                            Text(
                              'Profile Strength',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: GoogleFonts.inter(
                                fontSize: compact ? 5 : 7,
                                fontWeight: FontWeight.w500,
                                color: _muted,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
              final needs = Column(
                children: [
                  _NeedRow(
                    Icons.accessible_rounded,
                    const Color(0xFF6C63FF),
                    const Color(0xFFEEF0FF),
                    'Mobility',
                    mobility,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 5 : 8),
                  _NeedRow(
                    Icons.chat_bubble_rounded,
                    const Color(0xFF3B82F6),
                    const Color(0xFFE8F1FF),
                    'Communication',
                    comm,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 5 : 8),
                  _NeedRow(
                    Icons.people_alt_rounded,
                    const Color(0xFF22C55E),
                    const Color(0xFFE8F8EF),
                    'Assistance',
                    assist,
                    compact: compact,
                  ),
                ],
              );
              if (compact || inner.maxWidth < 130) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ring,
                    SizedBox(width: compact ? 4 : 8),
                    Expanded(child: needs),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ring,
                  const SizedBox(width: 12),
                  Expanded(child: needs),
                ],
              );
            },
          ),
          SizedBox(height: compact ? 8 : 12),
          _GhostBtn(
            label: 'View & Edit Profile',
            onTap: onEdit,
            compact: compact,
          ),
        ],
      ),
    );
  }

  static String _mobilityLabel(UserProfile? profile) {
    final aid = profile?.mobilityAid.trim() ?? '';
    if (aid.isEmpty) return 'Wheelchair user';
    if (aid.toLowerCase().contains('user')) return aid;
    return '$aid user';
  }

  static String _communicationLabel(UserProfile? profile) {
    if (profile == null) return 'Prefers text';
    final raw =
        (profile.communication['preferredContactMethod'] as String?)?.trim() ??
        '';
    if (raw.isEmpty) return 'Prefers text';
    final method = raw.toLowerCase();
    if (method.contains('text') ||
        method.contains('sms') ||
        method.contains('chat') ||
        method.contains('email') ||
        method.contains('message')) {
      return 'Prefers text';
    }
    if (method.contains('voice') ||
        method.contains('call') ||
        method.contains('phone')) {
      return 'Prefers voice';
    }
    return 'Prefers text';
  }
}

class _NeedRow extends StatelessWidget {
  const _NeedRow(
    this.icon,
    this.color,
    this.bg,
    this.title,
    this.subtitle, {
    this.compact = false,
  });
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 18.0 : 26.0;
    return Row(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(compact ? 6 : 8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: compact ? 11 : 15, color: color),
        ),
        SizedBox(width: compact ? 4 : 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: compact ? 8 : 11,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                  height: 1.15,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: compact ? 7 : 10,
                  color: _muted,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppointmentsCard extends StatelessWidget {
  const _AppointmentsCard({
    required this.appointments,
    required this.onViewAll,
    required this.onItem,
    this.compact = false,
  });

  final List<CareAppointment> appointments;
  final VoidCallback onViewAll;
  final ValueChanged<CareAppointment?> onItem;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final live = appointments.take(2).toList();
    return _WhiteCard(
      compact: compact,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Upcoming Appointments',
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: compact ? 9 : 12,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                    height: 1.15,
                  ),
                ),
              ),
              if (!compact)
                GestureDetector(
                  onTap: onViewAll,
                  child: Text(
                    'View all',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          if (compact)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onViewAll,
                child: Text(
                  'View all',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          SizedBox(height: compact ? 6 : 10),
          if (live.isNotEmpty)
            for (final a in live)
              _ApptRow(
                month: _month(a.startAt),
                day: '${a.startAt.day}',
                weekday: _weekday(a.startAt),
                title: a.kind == 'rehab'
                    ? 'Physiotherapy Session'
                    : 'Telehealth Consultation',
                subtitle: a.providerName,
                detail: a.isRemote ? 'Online Session' : a.whenLabel,
                time: _time(a.startAt),
                color: a.kind == 'rehab'
                    ? AppColors.primary
                    : const Color(0xFF818CF8),
                onTap: () => onItem(a),
                compact: compact,
              )
          else ...[
            _ApptRow(
              month: 'MAY',
              day: '20',
              weekday: 'Mon',
              title: 'Physiotherapy Session',
              subtitle: 'Access Rehab Center',
              detail: '12 Rue de la Santé, Paris',
              time: '10:00 AM',
              color: AppColors.primary,
              onTap: () => onItem(null),
              compact: compact,
            ),
            _ApptRow(
              month: 'MAY',
              day: '22',
              weekday: 'Wed',
              title: 'Telehealth Consultation',
              subtitle: 'Dr. Maria Dupont',
              detail: 'Online Session',
              time: '02:30 PM',
              color: const Color(0xFF818CF8),
              onTap: () => onItem(null),
              compact: compact,
            ),
          ],
        ],
      ),
    );
  }

  static String _month(DateTime d) {
    const m = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
    return m[d.month - 1];
  }

  static String _weekday(DateTime d) {
    const w = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return w[d.weekday - 1];
  }

  static String _time(DateTime d) {
    final h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    final am = h >= 12 ? 'PM' : 'AM';
    final hr = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${hr.toString().padLeft(2, '0')}:$m $am';
  }
}

class _ApptRow extends StatelessWidget {
  const _ApptRow({
    required this.month,
    required this.day,
    required this.weekday,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.time,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  final String month, day, weekday, title, subtitle, detail, time;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(bottom: compact ? 6 : 10),
        child: Row(
          children: [
            Container(
              width: compact ? 30 : 42,
              padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(compact ? 6 : 8),
              ),
              child: Column(
                children: [
                  Text(
                    month,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 6 : 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    day,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 11 : 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    weekday,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 6 : 8,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: compact ? 4 : 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 8 : 11,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                  if (!compact) ...[
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: _muted,
                      ),
                    ),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: _muted,
                      ),
                    ),
                  ] else
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        color: _muted,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: compact ? 7 : 9,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
                if (!compact)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: _muted,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PassportCard extends StatelessWidget {
  const _PassportCard({required this.onView, this.compact = false});
  final VoidCallback onView;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 40.0 : 56.0;
    return _WhiteCard(
      compact: compact,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Accessibility Passport',
              maxLines: compact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: compact ? 9 : 12,
                fontWeight: FontWeight.w800,
                color: _navy,
                height: 1.15,
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.badge_rounded, size: iconSize, color: AppColors.primary),
              Positioned(
                right: compact ? 8 : 72,
                top: compact ? 0 : 4,
                child: Container(
                  width: compact ? 14 : 18,
                  height: compact ? 14 : 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF14B8A6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: compact ? 9 : 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            'Show your needs anytime, anywhere',
            textAlign: TextAlign.center,
            maxLines: compact ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: compact ? 8 : 11,
              color: _muted,
              height: 1.2,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          _GhostBtn(label: 'View Passport', onTap: onView, compact: compact),
        ],
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  const _GhostBtn({
    required this.label,
    required this.onTap,
    this.compact = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F0FF),
      borderRadius: BorderRadius.circular(compact ? 8 : 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 6 : 12,
            compact ? 6 : 9,
            compact ? 4 : 8,
            compact ? 6 : 9,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: compact ? 8 : 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: compact ? 14 : 18,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.value, {this.strokeWidth = 8});
  final double value;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - strokeWidth;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * value.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = const Color(0xFF3B82F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.strokeWidth != strokeWidth;
}
