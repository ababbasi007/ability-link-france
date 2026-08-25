import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

class _ServiceItem {
  const _ServiceItem(this.label, this.subtitle, this.icon, this.bg, this.fg);
  final String label;
  final String subtitle;
  final IconData icon;
  final Color bg;
  final Color fg;
}

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key, required this.onTap, this.onViewAll});

  final ValueChanged<String> onTap;
  final VoidCallback? onViewAll;

  static const _items = [
    _ServiceItem(
      'Ability Map',
      'Accessible places',
      Icons.map_rounded,
      Color(0xFFD1FAE5),
      Color(0xFF059669),
    ),
    _ServiceItem(
      'Tele Rehab',
      'Remote therapy',
      Icons.accessibility_new_rounded,
      Color(0xFFCCFBF1),
      Color(0xFF0D9488),
    ),
    _ServiceItem(
      'Tele Health',
      'Online care',
      Icons.medical_services_rounded,
      Color(0xFFDBEAFE),
      Color(0xFF2563EB),
    ),
    _ServiceItem(
      'Accessible Tourism',
      'Plan your trip',
      Icons.flight_takeoff_rounded,
      Color(0xFFFFEDD5),
      Color(0xFFEA580C),
    ),
    _ServiceItem(
      'Accessible Education',
      'Courses & training',
      Icons.school_rounded,
      Color(0xFFE0E7FF),
      Color(0xFF4F46E5),
    ),
    _ServiceItem(
      'Jobs',
      'Inclusive work',
      Icons.work_rounded,
      Color(0xFFDBEAFE),
      Color(0xFF1D4ED8),
    ),
    _ServiceItem(
      'Services',
      'Book support',
      Icons.handyman_rounded,
      Color(0xFFFFEDD5),
      Color(0xFFC2410C),
    ),
    _ServiceItem(
      'Community',
      'Connect & share',
      Icons.groups_rounded,
      Color(0xFFCCFBF1),
      Color(0xFF0F766E),
    ),
    _ServiceItem(
      'Accessible Transport',
      'Get around',
      Icons.directions_bus_rounded,
      Color(0xFFEDE9FE),
      Color(0xFF7C3AED),
    ),
    _ServiceItem(
      'Caregiver',
      'Family support',
      Icons.volunteer_activism_rounded,
      Color(0xFFF3E8FF),
      Color(0xFF9333EA),
    ),
    _ServiceItem(
      'Assistive Technology',
      'Tools & devices',
      Icons.headphones_rounded,
      Color(0xFFE0F2FE),
      Color(0xFF0284C7),
    ),
    _ServiceItem(
      'Benefits',
      'Govt. programs',
      Icons.account_balance_wallet_rounded,
      Color(0xFFD1FAE5),
      Color(0xFF047857),
    ),
    _ServiceItem(
      'Rights and Legal',
      'Know your rights',
      Icons.balance_rounded,
      Color(0xFFFEF3C7),
      Color(0xFFB45309),
    ),
    _ServiceItem(
      'AI Assistant',
      'Ask anything',
      Icons.auto_awesome_rounded,
      Color(0xFFE0F2FE),
      Color(0xFF0369A1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Explore Services',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
            childAspectRatio: 0.80,
          ),
          itemBuilder: (context, index) {
            final item = _items[index];
            return InkWell(
              onTap: () => onTap(item.label),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: item.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.icon, color: item.fg, size: 26),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
