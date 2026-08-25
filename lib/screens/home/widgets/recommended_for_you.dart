import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

class _RecItem {
  const _RecItem({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
    required this.image,
    required this.meta,
    required this.rating,
    required this.ratingColor,
  });

  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;
  final String image;
  final String meta;
  final String rating;
  final Color ratingColor;
}

/// Horizontal “Recommended for You” cards matching the homepage mockup.
class RecommendedForYou extends StatelessWidget {
  const RecommendedForYou({
    super.key,
    required this.onSeeAll,
    this.onTap,
  });

  final VoidCallback onSeeAll;
  final ValueChanged<String>? onTap;

  static const _items = [
    _RecItem(
      title: 'Coffee Access',
      subtitle: 'Café',
      tag: 'Nearby',
      tagColor: AppColors.primary,
      image: 'assets/images/rec_coffee.png',
      meta: '0.3 km away',
      rating: '4.8',
      ratingColor: AppColors.primary,
    ),
    _RecItem(
      title: 'Home Care Support',
      subtitle: 'Health & Care',
      tag: 'Service',
      tagColor: Color(0xFFD97706),
      image: 'assets/images/rec_homecare.png',
      meta: '',
      rating: '4.9',
      ratingColor: AppColors.primary,
    ),
    _RecItem(
      title: 'Digital Marketing Specialist',
      subtitle: 'Remote',
      tag: 'Job',
      tagColor: Color(0xFF7C3AED),
      image: 'assets/images/rec_job.png',
      meta: '',
      rating: '4.6',
      ratingColor: Color(0xFF7C3AED),
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
                'Recommended for You',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  'See all',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final item = _items[i];
              return _RecCard(
                item: item,
                onTap: () => onTap?.call(item.title),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecCard extends StatelessWidget {
  const _RecCard({required this.item, required this.onTap});

  final _RecItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 96,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    item.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.primaryLight,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: item.tagColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.tag,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (item.meta.isNotEmpty)
                        Expanded(
                          child: Text(
                            item.meta,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.ratingColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: item.ratingColor,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item.rating,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: item.ratingColor,
                              ),
                            ),
                          ],
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
