import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/care_appointment.dart';
import '../../../theme/app_colors.dart';

class YourDayAiRow extends StatelessWidget {
  const YourDayAiRow({
    super.key,
    required this.appointments,
    required this.onViewAll,
    required this.onItem,
    required this.onViewRoute,
  });

  final List<CareAppointment> appointments;
  final VoidCallback onViewAll;
  final ValueChanged<CareAppointment> onItem;
  final VoidCallback onViewRoute;

  @override
  Widget build(BuildContext context) {
    final items = appointments.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your Day',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E1B4B),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onViewAll,
                      child: Text(
                        'View All',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  GestureDetector(
                    onTap: onViewAll,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'No visits yet — book from Telehealth.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF1E1B4B),
                        ),
                      ),
                    ),
                  )
                else
                  for (final a in items) ...[
                    _DayTile(appointment: a, onTap: () => onItem(a)),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI For You',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: const Color(0xFFEAF2FA),
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onViewRoute,
                    child: SizedBox(
                      height: 168,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/ai_for_you_map.png',
                            fit: BoxFit.cover,
                            alignment: const Alignment(0.15, 0.1),
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: Color(0xFFEAF2FA),
                              child: CustomPaint(
                                painter: _MiniMapPainter(),
                                child: SizedBox.expand(),
                              ),
                            ),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xE6EAF2FA),
                                  Color(0x66EAF2FA),
                                  Color(0x00EAF2FA),
                                ],
                                stops: [0, 0.42, 0.78],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Accessible route to your physiotherapy session is ready.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E1B4B),
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x14000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'View Route',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 12,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _Dot(active: true),
                                    SizedBox(width: 4),
                                    _Dot(active: false),
                                    SizedBox(width: 4),
                                    _Dot(active: false),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.appointment, required this.onTap});

  final CareAppointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final local = appointment.startAt.toLocal();
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final am = local.hour >= 12 ? 'PM' : 'AM';
    final time =
        '${hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} $am';
    final online = appointment.isRemote;
    final accent = online ? AppColors.primary : const Color(0xFF3B82F6);
    final title = appointment.kind == 'rehab'
        ? 'Physiotherapy Session'
        : 'Telehealth Appointment';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  time,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E1B4B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      appointment.providerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  online ? 'Online' : 'Clinic',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 12 : 5,
      height: 5,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : const Color(0xFF9CA3AF),
        borderRadius: BorderRadius.circular(4),
        boxShadow: active
            ? const [BoxShadow(color: Color(0x33000000), blurRadius: 2)]
            : null,
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  const _MiniMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFF93C5FD)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.15,
        size.width * 0.82,
        size.height * 0.35,
      );
    canvas.drawPath(path, road);
    final pin = Paint()..color = const Color(0xFF6C63FF);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.32), 7, pin);
    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.75),
      5,
      Paint()..color = const Color(0xFF22C55E),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
