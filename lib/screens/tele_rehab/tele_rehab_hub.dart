import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../../widgets/decoded_network_image.dart';

const _forest = AppColors.primary;
const _ink = Color(0xFF0F3D2E);
const _muted = Color(0xFF6B7280);
const _bg = Color(0xFFFAFBFA);
const _cardBorder = Color(0xFFE8ECEB);

TextStyle _txt({
  double size = 13,
  FontWeight weight = FontWeight.w500,
  Color color = _ink,
  double height = 1.3,
}) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
);

class RehabHubPlanItem {
  const RehabHubPlanItem({
    required this.title,
    required this.minutes,
    required this.done,
    required this.image,
  });

  final String title;
  final int minutes;
  final bool done;
  final String image;
}

class RehabHubView extends StatelessWidget {
  const RehabHubView({
    super.key,
    required this.name,
    required this.unreadBadge,
    required this.therapistName,
    required this.whenLabel,
    required this.durationMin,
    required this.photoAsset,
    required this.plan,
    required this.onBack,
    required this.onBell,
    required this.onCalendar,
    required this.onVideo,
    required this.onPlans,
    required this.onProgress,
    required this.onHealth,
    required this.onMessages,
    required this.onLibrary,
    required this.onJoin,
    required this.onReschedule,
    required this.onMore,
    required this.onPlanItem,
    required this.onAskAi,
  });

  final String name;
  final String unreadBadge;
  final String therapistName;
  final String whenLabel;
  final int durationMin;
  final String photoAsset;
  final List<RehabHubPlanItem> plan;
  final VoidCallback onBack;
  final VoidCallback onBell;
  final VoidCallback onCalendar;
  final VoidCallback onVideo;
  final VoidCallback onPlans;
  final VoidCallback onProgress;
  final VoidCallback onHealth;
  final VoidCallback onMessages;
  final VoidCallback onLibrary;
  final VoidCallback onJoin;
  final VoidCallback onReschedule;
  final VoidCallback onMore;
  final ValueChanged<int> onPlanItem;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bg,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              children: [
                _HeroBanner(onBack: onBack, onBell: onBell),
                const SizedBox(height: 12),
                _QuickActions(
                  onVideo: onVideo,
                  onCalendar: onCalendar,
                  onPlans: onPlans,
                  onProgress: onProgress,
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  title: 'Upcoming Session',
                  action: 'View all',
                  onTap: onMore,
                ),
                const SizedBox(height: 8),
                _UpcomingCard(
                  therapistName: therapistName,
                  whenLabel: whenLabel,
                  photoAsset: photoAsset,
                  onJoin: onJoin,
                ),
                const SizedBox(height: 14),
                _SectionTitle(
                  title: 'Today’s Progress',
                  action: 'View details',
                  onTap: onProgress,
                ),
                const SizedBox(height: 8),
                const _ProgressCard(),
                const SizedBox(height: 14),
                _SectionTitle(
                  title: 'Today’s Exercises',
                  action: 'View all',
                  onTap: onLibrary,
                ),
                const SizedBox(height: 8),
                _ExercisesRow(plan: plan, onPlanItem: onPlanItem),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Combined header + hero banner matching the mockup exactly.
/// Title text sits on the left, the illustration image on the right.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onBack, required this.onBell});

  final VoidCallback onBack;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── top nav row ────────────────────────────────────────────────
        Row(
          children: [
            _IconBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
            const Spacer(),
            Stack(
              children: [
                _IconBtn(icon: Icons.notifications_none_rounded, onTap: onBell),
                const Positioned(
                  right: 7,
                  top: 7,
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // ── title + illustration side-by-side ──────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // left: title text
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tele',
                    style: _txt(size: 32, weight: FontWeight.w800),
                  ),
                  Text(
                    'Rehabilitation',
                    style: _txt(size: 32, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rehab care, anywhere you are',
                    style: _txt(size: 12, color: _muted),
                  ),
                ],
              ),
            ),
            // right: illustration image — fixed height to match mockup
            Expanded(
              flex: 6,
              child: AspectRatio(
                aspectRatio: 235 / 240,
                child: Image.asset(
                  'assets/images/rehab/hero_illustration.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onVideo,
    required this.onCalendar,
    required this.onPlans,
    required this.onProgress,
  });

  final VoidCallback onVideo;
  final VoidCallback onCalendar;
  final VoidCallback onPlans;
  final VoidCallback onProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionItem(
              icon: Icons.videocam_rounded,
              title: 'Start\nSession',
              caption: 'Connect with\nyour therapist',
              onTap: onVideo,
            ),
          ),
          Expanded(
            child: _ActionItem(
              icon: Icons.calendar_month_rounded,
              title: 'Book\nAppointment',
              caption: 'Schedule your\nrehab session',
              onTap: onCalendar,
            ),
          ),
          Expanded(
            child: _ActionItem(
              icon: Icons.fitness_center_rounded,
              title: 'Exercise\nProgram',
              caption: 'View your\npersonal plan',
              onTap: onPlans,
            ),
          ),
          Expanded(
            child: _ActionItem(
              icon: Icons.equalizer_rounded,
              title: 'Track\nProgress',
              caption: 'Monitor your\nimprovement',
              onTap: onProgress,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF6EF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _forest, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: _txt(size: 12, weight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: _txt(size: 10.5, color: _muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: _txt(size: 16, weight: FontWeight.w800)),
        ),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              action,
              style: _txt(size: 12, color: _forest, weight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.therapistName,
    required this.whenLabel,
    required this.photoAsset,
    required this.onJoin,
  });

  final String therapistName;
  final String whenLabel;
  final String photoAsset;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAF6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: Image.asset(
                  photoAsset,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 54,
                    height: 54,
                    color: AppColors.primaryLight,
                    child: const Icon(Icons.person, color: _forest),
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                top: 0,
                child: CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(therapistName, style: _txt(size: 14, weight: FontWeight.w800)),
                Text('Physiotherapist', style: _txt(size: 11.5, color: _muted)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: _muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        whenLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _txt(size: 11.5, color: _muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onJoin,
            style: FilledButton.styleFrom(
              backgroundColor: _forest,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.videocam_rounded, size: 16),
            label: Text(
              'Join Session',
              style: _txt(size: 12, weight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 0.7,
                      strokeWidth: 7,
                      color: _forest,
                      backgroundColor: const Color(0xFFE9EFED),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('70%', style: _txt(size: 32 / 2, weight: FontWeight.w800)),
                        Text('Goal', style: _txt(size: 11, color: _muted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Great job! You’re making progress.',
                      style: _txt(size: 14, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep going to reach your weekly goal.',
                      style: _txt(size: 12, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _cardBorder),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _Metric(icon: Icons.schedule_rounded, value: '30 min', label: 'Completed')),
              Expanded(child: _Metric(icon: Icons.check_circle_outline_rounded, value: '5', label: 'Exercises')),
              Expanded(child: _Metric(icon: Icons.local_fire_department_rounded, value: '120', label: 'Calories', iconColor: Color(0xFFF97316))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor = _forest,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: iconColor),
        const SizedBox(height: 3),
        Text(value, style: _txt(size: 13, weight: FontWeight.w700)),
        Text(label, style: _txt(size: 10.5, color: _muted)),
      ],
    );
  }
}

class _ExercisesRow extends StatelessWidget {
  const _ExercisesRow({required this.plan, required this.onPlanItem});

  final List<RehabHubPlanItem> plan;
  final ValueChanged<int> onPlanItem;

  @override
  Widget build(BuildContext context) {
    final items = plan.isEmpty
        ? const [
            RehabHubPlanItem(
              title: 'Shoulder\nMobilization',
              minutes: 10,
              done: false,
              image: 'assets/images/rehab/ex_shoulder.png',
            ),
            RehabHubPlanItem(
              title: 'Knee\nStrengthening',
              minutes: 12,
              done: false,
              image: 'assets/images/rehab/ex_knee.png',
            ),
            RehabHubPlanItem(
              title: 'Lower Back\nStretch',
              minutes: 30,
              done: true,
              image: 'assets/images/rehab/ex_lower_back.png',
            ),
          ]
        : plan;

    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => onPlanItem(index),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 148,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cardBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // figure illustration (left)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.image.startsWith('http')
                        ? DecodedNetworkImage(
                            item.image,
                            width: 56,
                            height: 82,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 56,
                              height: 82,
                              color: AppColors.primaryLight,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                color: _forest,
                              ),
                            ),
                          )
                        : Image.asset(
                            item.image,
                            width: 56,
                            height: 82,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (_, _, _) => Container(
                              width: 56,
                              height: 82,
                              color: AppColors.primaryLight,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                color: _forest,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  // title + meta + play (right)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          style: _txt(size: 11.5, weight: FontWeight.w700, height: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.done ? 3 : 2} sets  •  ${item.minutes} ${item.minutes > 20 ? 'sec' : 'reps'}',
                          style: _txt(size: 10, color: _muted),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: _forest,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF374151)),
      ),
    );
  }
}
