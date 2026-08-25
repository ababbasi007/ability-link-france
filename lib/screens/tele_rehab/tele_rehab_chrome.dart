import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../../widgets/decoded_network_image.dart';

const _navy = Color(0xFF1E1B4B);
const _muted = Color(0xFF6B7280);
const _cardShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
];

TextStyle _title([double size = 16]) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  fontWeight: FontWeight.w800,
  color: _navy,
);

TextStyle _link() => GoogleFonts.plusJakartaSans(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: AppColors.primary,
);

class RehabCircleBtn extends StatelessWidget {
  const RehabCircleBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE6E7EE)),
              ),
              child: Icon(icon, size: 20, color: _navy),
            ),
          ),
        ),
        if (badge != null && badge!.isNotEmpty)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16),
              height: 16,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.badge,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class RehabHeaderBar extends StatelessWidget {
  const RehabHeaderBar({
    super.key,
    required this.onBack,
    required this.onBell,
    required this.onChat,
    this.unread = 0,
  });

  final VoidCallback onBack;
  final VoidCallback onBell;
  final VoidCallback onChat;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          RehabCircleBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
          Expanded(
            child: Column(
              children: [
                Text('Tele-Rehabilitation', style: _title(17)),
                Text(
                  'Recover. Restore. Rebuild.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          RehabCircleBtn(
            icon: Icons.notifications_none_rounded,
            onTap: onBell,
            badge: unread > 0 ? (unread > 9 ? '9+' : '$unread') : null,
          ),
          const SizedBox(width: 8),
          RehabCircleBtn(
            icon: Icons.chat_bubble_outline_rounded,
            onTap: onChat,
          ),
        ],
      ),
    );
  }
}

class RehabHeroCard extends StatelessWidget {
  const RehabHeroCard({
    super.key,
    required this.name,
    required this.streak,
    required this.consistency,
    required this.onProgress,
  });

  final String name;
  final int streak;
  final int consistency;
  final VoidCallback onProgress;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B47F5), Color(0xFF7B68F5), Color(0xFFB9A6FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              right: -6,
              top: 0,
              bottom: 32,
              width: 152,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/rehab/hero_yoga.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 230),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$_greeting, ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: '$name 👋',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "You're doing great! Keep going 💪",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _StatsPill(
                          streak: streak,
                          consistency: consistency,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(
                          onTap: onProgress,
                          borderRadius: BorderRadius.circular(22),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.show_chart_rounded,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'View Progress',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsPill extends StatelessWidget {
  const _StatsPill({required this.streak, required this.consistency});

  final int streak;
  final int consistency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                ),
                Text(
                  '$streak Days',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: const Color(0xFFE8E8EE),
          ),
          const Icon(
            Icons.local_fire_department_rounded,
            size: 18,
            color: Color(0xFFF97316),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consistency',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                ),
                Text(
                  '$consistency%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum RehabPlanStatus { done, inProgress, pending }

class RehabPlanCardData {
  const RehabPlanCardData({
    required this.title,
    required this.meta,
    required this.sets,
    required this.time,
    required this.status,
    required this.image,
    required this.progressLabel,
    this.reps,
  });

  final String title;
  final String meta;
  final String sets;
  final String? reps;
  final String time;
  final RehabPlanStatus status;
  final String image;
  final String progressLabel;
}

class RehabTodaysPlan extends StatelessWidget {
  const RehabTodaysPlan({
    super.key,
    required this.items,
    required this.onSeeAll,
    required this.onOpen,
  });

  final List<RehabPlanCardData> items;
  final VoidCallback onSeeAll;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text("Today's Plan", style: _title())),
            GestureDetector(
              onTap: onSeeAll,
              child: Text('See Full Plan', style: _link()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          RehabPlanCard(item: items[i], onTap: () => onOpen(i)),
        ],
      ],
    );
  }
}

class RehabPlanCard extends StatelessWidget {
  const RehabPlanCard({super.key, required this.item, this.onTap});

  final RehabPlanCardData item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _cardShadow,
            border: Border.all(color: const Color(0xFFF0F1F5)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _RehabImage(src: item.image, width: 62, height: 62),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                    Text(
                      item.meta,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Meta(Icons.fitness_center_rounded, item.sets),
                        if (item.reps != null) ...[
                          const SizedBox(width: 8),
                          _Meta(Icons.sync_rounded, item.reps!),
                        ],
                        const SizedBox(width: 8),
                        _Meta(Icons.schedule_rounded, item.time),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              RehabStatusRing(status: item.status, label: item.progressLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: _muted),
        ),
      ],
    );
  }
}

class RehabStatusRing extends StatelessWidget {
  const RehabStatusRing({super.key, required this.status, required this.label});

  final RehabPlanStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final double progress;
    switch (status) {
      case RehabPlanStatus.done:
        color = const Color(0xFF22C55E);
        progress = 1;
      case RehabPlanStatus.inProgress:
        color = const Color(0xFFF97316);
        progress = 2 / 3;
      case RehabPlanStatus.pending:
        color = const Color(0xFF8B7CF6);
        progress = 0;
    }

    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              value: status == RehabPlanStatus.pending ? 1 : progress,
              strokeWidth: 3.6,
              backgroundColor: const Color(0xFFECEEF3),
              color: status == RehabPlanStatus.pending
                  ? const Color(0xFFD8D0F8)
                  : color,
              strokeCap: StrokeCap.round,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: switch (status) {
              RehabPlanStatus.done => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Done',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              RehabPlanStatus.inProgress => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'In Progress',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 6.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                      height: 1.05,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: label.split('/').first,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        TextSpan(
                          text:
                              '/${label.split('/').length > 1 ? label.split('/').last : '3'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              RehabPlanStatus.pending => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pending',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const Icon(
                    Icons.play_arrow_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}

class RehabProgressSessionRow extends StatelessWidget {
  const RehabProgressSessionRow({
    super.key,
    required this.weekValues,
    required this.onJoin,
    required this.onMore,
    this.providerName = 'Dr. Ali Hassan',
    this.specialty = 'Physiotherapist',
    this.whenLabel = 'Tomorrow, 11:00 AM',
    this.durationMin = 30,
    this.photoUrl,
  });

  final List<double> weekValues;
  final VoidCallback onJoin;
  final VoidCallback onMore;
  final String providerName;
  final String specialty;
  final String whenLabel;
  final int durationMin;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 228,
      child: Row(
        children: [
          Expanded(child: RehabWeeklyProgressCard(values: weekValues)),
          const SizedBox(width: 10),
          Expanded(
            child: RehabUpcomingSessionCard(
              onJoin: onJoin,
              onMore: onMore,
              providerName: providerName,
              specialty: specialty,
              whenLabel: whenLabel,
              durationMin: durationMin,
              photoUrl: photoUrl,
            ),
          ),
        ],
      ),
    );
  }
}

class RehabWeeklyProgressCard extends StatelessWidget {
  const RehabWeeklyProgressCard({super.key, required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    var peak = 5;
    final pts = values.isEmpty
        ? const [0.35, 0.45, 0.4, 0.55, 0.62, 0.78, 0.7]
        : values;
    for (var i = 1; i < pts.length; i++) {
      if (pts[i] >= pts[peak.clamp(0, pts.length - 1)]) peak = i;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Progress', style: _title(13)),
          const SizedBox(height: 10),
          Expanded(
            child: CustomPaint(
              painter: RehabWeekChartPainter(pts),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < days.length; i++)
                Text(
                  days[i],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: i == peak ? FontWeight.w800 : FontWeight.w500,
                    color: i == peak
                        ? AppColors.primary
                        : const Color(0xFF9CA3AF),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class RehabWeekChartPainter extends CustomPainter {
  RehabWeekChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = values.isEmpty
        ? [0.35, 0.45, 0.4, 0.55, 0.62, 0.78, 0.7]
        : values;
    final points = <Offset>[];
    for (var i = 0; i < pts.length; i++) {
      final x = size.width * (i / (pts.length - 1));
      final y = size.height * (1 - pts[i].clamp(0.08, 1));
      points.add(Offset(x, y));
    }

    final grid = Paint()
      ..color = const Color(0xFFE8E9F0)
      ..strokeWidth = 1;
    for (final p in points) {
      canvas.drawLine(Offset(p.dx, 4), Offset(p.dx, size.height), grid);
    }

    final fill = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fill.lineTo(p.dx, p.dy);
    }
    fill
      ..lineTo(points.last.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), [
          const Color(0xFF6C63FF).withValues(alpha: 0.32),
          const Color(0xFF6C63FF).withValues(alpha: 0.02),
        ]),
    );

    final line = Paint()
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, line);

    var peakI = 0;
    for (var i = 1; i < pts.length; i++) {
      if (pts[i] >= pts[peakI]) peakI = i;
    }

    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(
        points[i],
        3.4,
        Paint()..color = const Color(0xFF6C63FF),
      );
      canvas.drawCircle(points[i], 1.8, Paint()..color = Colors.white);
    }

    final peak = points[peakI];
    final label = '${(pts[peakI] * 100).round()}%';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final tipH = tp.height + 8;
    final tipW = tp.width + 12;
    var cx = peak.dx;
    cx = cx.clamp(tipW / 2, size.width - tipW / 2);
    final top = math.max(2.0, peak.dy - 22);
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, top), width: tipW, height: tipH),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFF6C63FF));
    final tri = Path()
      ..moveTo(peak.dx - 4, top + tipH / 2 - 1)
      ..lineTo(peak.dx + 4, top + tipH / 2 - 1)
      ..lineTo(peak.dx, top + tipH / 2 + 5)
      ..close();
    canvas.drawPath(tri, Paint()..color = const Color(0xFF6C63FF));
    tp.paint(canvas, Offset(cx - tp.width / 2, top - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant RehabWeekChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

class RehabUpcomingSessionCard extends StatelessWidget {
  const RehabUpcomingSessionCard({
    super.key,
    required this.onJoin,
    required this.onMore,
    required this.providerName,
    required this.specialty,
    required this.whenLabel,
    required this.durationMin,
    this.photoUrl,
  });

  final VoidCallback onJoin;
  final VoidCallback onMore;
  final String providerName;
  final String specialty;
  final String whenLabel;
  final int durationMin;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Upcoming Session', style: _title(13))),
              GestureDetector(
                onTap: onMore,
                child: const Icon(
                  Icons.more_horiz,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          Text(
            'Video Session with Therapist',
            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: _muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                backgroundImage:
                    photoUrl != null && photoUrl!.startsWith('http')
                    ? NetworkImage(photoUrl!)
                    : const AssetImage('assets/images/rehab/therapist.png')
                          as ImageProvider,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      providerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                    Text(
                      specialty,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  whenLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: _muted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.videocam_outlined,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 3),
              Text(
                '$durationMin min',
                style: GoogleFonts.plusJakartaSans(fontSize: 9, color: _muted),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onJoin,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Join Session',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
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

class RehabQuickActions extends StatelessWidget {
  const RehabQuickActions({super.key, required this.onAction});

  final ValueChanged<int> onAction;

  /// Illustrations carry their own tinted background, so they replace the circle
  /// rather than sit inside it. The icon and colours stay as the fallback.
  static const _actions = [
    (
      Icons.videocam_rounded,
      'Join Live\nSession',
      Color(0xFF6C63FF),
      Color(0xFFEEF0FF),
      'assets/images/rehab/qa_live.png',
    ),
    (
      Icons.calendar_month_rounded,
      'Book\nSession',
      Color(0xFF14B8A6),
      Color(0xFFE6FAF7),
      'assets/images/rehab/qa_book.png',
    ),
    (
      Icons.assignment_rounded,
      'My\nExercises',
      Color(0xFFF97316),
      Color(0xFFFFF1E8),
      'assets/images/rehab/qa_exercises.png',
    ),
    (
      Icons.bar_chart_rounded,
      'Progress\nReports',
      Color(0xFF3B82F6),
      Color(0xFFE8F1FF),
      'assets/images/rehab/qa_reports.png',
    ),
    (
      Icons.chat_bubble_rounded,
      'Message\nTherapist',
      Color(0xFFEC4899),
      Color(0xFFFCE7F3),
      'assets/images/rehab/qa_message.png',
    ),
    (
      Icons.description_rounded,
      'Upload\nDocument',
      Color(0xFF22C55E),
      Color(0xFFE8F8EF),
      'assets/images/rehab/qa_upload.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: _title()),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < _actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: () => onAction(i),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(2, 12, 2, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _cardShadow,
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          _actions[i].$5,
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, _, _) => Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _actions[i].$4,
                            ),
                            child: Icon(
                              _actions[i].$1,
                              color: _actions[i].$3,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _actions[i].$2,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: _navy,
                            height: 1.15,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
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

/// Rows rather than the narrow columns used above: these labels are sentences,
/// and they have to stay readable at the largest text scale the app offers.
class RehabRecoveryTools extends StatelessWidget {
  const RehabRecoveryTools({super.key, required this.onTool});

  final ValueChanged<int> onTool;

  static const _tools = [
    (
      Icons.monitor_heart_rounded,
      'Health & recovery log',
      'Track pain, energy and mobility',
      Color(0xFFEC4899),
      Color(0xFFFCE7F3),
    ),
    (
      Icons.alarm_rounded,
      'Rehab reminders',
      'Exercise and appointment nudges',
      Color(0xFFF97316),
      Color(0xFFFFF1E8),
    ),
    (
      Icons.sticky_note_2_rounded,
      'Session notes',
      'Your record of therapist advice',
      Color(0xFF3B82F6),
      Color(0xFFE8F1FF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recovery Tools', style: _title()),
        const SizedBox(height: 12),
        for (var i = 0; i < _tools.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          InkWell(
            onTap: () => onTool(i),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _tools[i].$5,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_tools[i].$1, color: _tools[i].$4, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tools[i].$2,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _tools[i].$3,
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
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class RehabExerciseLibrary extends StatelessWidget {
  const RehabExerciseLibrary({
    super.key,
    required this.onViewAll,
    required this.onCategory,
  });

  final VoidCallback onViewAll;
  final ValueChanged<String> onCategory;

  static const _cats = [
    (
      'upper',
      'Upper Body',
      '28 Exercises',
      Color(0xFF6C63FF),
      Color(0xFFEEF0FF),
      Icons.fitness_center_rounded,
      'assets/images/rehab/lib_upper.png',
    ),
    (
      'lower',
      'Lower Body',
      '32 Exercises',
      Color(0xFF14B8A6),
      Color(0xFFE6FAF7),
      Icons.airline_seat_legroom_extra_rounded,
      'assets/images/rehab/lib_lower.png',
    ),
    (
      'flexibility',
      'Flexibility',
      '25 Exercises',
      Color(0xFFF97316),
      Color(0xFFFFF4E5),
      Icons.self_improvement_rounded,
      'assets/images/rehab/lib_flex.png',
    ),
    (
      'strength',
      'Strength',
      '30 Exercises',
      Color(0xFF3B82F6),
      Color(0xFFE8F1FF),
      Icons.fitness_center_rounded,
      'assets/images/rehab/lib_strength.png',
    ),
    (
      'breathing',
      'Breathing',
      '18 Exercises',
      Color(0xFFEC4899),
      Color(0xFFFCE7F3),
      Icons.air_rounded,
      'assets/images/rehab/lib_breath.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text('Exercise Library', style: _title())),
            GestureDetector(
              onTap: onViewAll,
              child: Text('View All', style: _link()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < _cats.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => onCategory(_cats[i].$1),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _cardShadow,
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          _cats[i].$7,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, _, _) => Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _cats[i].$5,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _cats[i].$6,
                              color: _cats[i].$4,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _cats[i].$2,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                          ),
                        ),
                        Text(
                          _cats[i].$3,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8,
                            color: _muted,
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
      ],
    );
  }
}

class _RehabImage extends StatelessWidget {
  const _RehabImage({
    required this.src,
    required this.width,
    required this.height,
  });

  final String src;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      color: AppColors.primaryLight,
      child: const Icon(Icons.fitness_center, color: AppColors.primary),
    );
    if (src.startsWith('assets/')) {
      return Image.asset(
        src,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return DecodedNetworkImage(
      src,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
