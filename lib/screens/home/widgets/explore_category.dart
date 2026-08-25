import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/decoded_network_image.dart';

const _navy = Color(0xFF1E1B4B);

class ExploreByCategory extends StatelessWidget {
  const ExploreByCategory({
    super.key,
    required this.onViewAll,
    required this.onCategory,
  });

  final VoidCallback onViewAll;
  final ValueChanged<String> onCategory;

  static const _cats = [
    (
      'Hospitals',
      'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=300&h=200&fit=crop',
    ),
    (
      'Clinics',
      'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=300&h=200&fit=crop',
    ),
    (
      'Therapists',
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=300&h=200&fit=crop',
    ),
    (
      'Pharmacies',
      'https://images.unsplash.com/photo-1585435557343-3b092031d5ad?w=300&h=200&fit=crop',
    ),
    (
      'Rehab Centers',
      'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=300&h=200&fit=crop',
    ),
    (
      'Psychologists',
      'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=300&h=200&fit=crop',
    ),
    (
      'Dentists',
      'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=300&h=200&fit=crop',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Explore by Category',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onViewAll,
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: GoogleFonts.inter(
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
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _cats.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final cat = _cats[i];
              return InkWell(
                onTap: () => onCategory(cat.$1),
                child: SizedBox(
                  width: 92,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DecodedNetworkImage(
                          cat.$2,
                          width: 92,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 92,
                            height: 58,
                            color: AppColors.primaryLight,
                            child: const Icon(
                              Icons.local_hospital_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cat.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
