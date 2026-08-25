import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/place.dart';
import '../../theme/app_colors.dart';
import '../../widgets/decoded_network_image.dart';

class MapHeaderBar extends StatelessWidget {
  const MapHeaderBar({
    super.key,
    required this.showBack,
    required this.onBack,
    required this.searchOpen,
    required this.search,
    required this.onToggleSearch,
    required this.onSearch,
    this.onSearchSubmitted,
    required this.onFilter,
  });

  final bool showBack;
  final VoidCallback onBack;
  final bool searchOpen;
  final TextEditingController search;
  final VoidCallback onToggleSearch;
  final VoidCallback onSearch;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: showBack ? onBack : onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accessibility Map',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    Text(
                      'Find accessible places & plan barrier-free routes.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Search',
                onPressed: onToggleSearch,
                icon: Icon(
                  searchOpen ? Icons.close_rounded : Icons.search_rounded,
                ),
              ),
              IconButton(
                tooltip: 'Filters',
                onPressed: onFilter,
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          if (searchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: TextField(
                controller: search,
                onChanged: (_) => onSearch(),
                onSubmitted: onSearchSubmitted,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search places, features, address…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            search.clear();
                            onSearch();
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MapCategoryChip extends StatelessWidget {
  const MapCategoryChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : const Color(0xFF1E1B4B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF1E1B4B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapScoreLegend extends StatelessWidget {
  const MapScoreLegend({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      (Color(0xFF22C55E), 'Excellent (90-100)'),
      (Color(0xFFEAB308), 'Good (70-89)'),
      (Color(0xFFF97316), 'Average (40-69)'),
      (Color(0xFFEF4444), 'Poor (0-39)'),
      (Color(0xFF9CA3AF), 'Not Rated'),
    ];
    return Container(
      width: 168,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.wb_sunny_rounded,
                color: Color(0xFFF59E0B),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '24°C',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Good Air Quality',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Divider(height: 14),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 14, color: r.$1),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r.$2,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10),
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

class MapRoundBtn extends StatelessWidget {
  const MapRoundBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
        ),
      ],
    );
  }
}

class MapNavigateBtn extends StatelessWidget {
  const MapNavigateBtn({super.key, required this.onTap, required this.busy});

  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 3,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: busy ? null : onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                busy ? Icons.hourglass_top_rounded : Icons.near_me_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Navigate',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class MapMyLocationChip extends StatelessWidget {
  const MapMyLocationChip({
    super.key,
    required this.onTap,
    required this.locating,
  });

  final VoidCallback onTap;
  final bool locating;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 2,
      child: InkWell(
        onTap: locating ? null : onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                locating ? Icons.hourglass_top_rounded : Icons.near_me_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'My Location',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlanAccessibleRouteBanner extends StatelessWidget {
  const PlanAccessibleRouteBanner({
    super.key,
    required this.onPlan,
    required this.busy,
  });

  final VoidCallback onPlan;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan Accessible Route',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
                Text(
                  'Get the best barrier-free route based on your needs.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: busy ? null : onPlan,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  busy ? '…' : 'Plan Route',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NearbyPlaceCard extends StatelessWidget {
  const NearbyPlaceCard({
    super.key,
    required this.place,
    required this.categoryColor,
    required this.categoryIcon,
    required this.scoreColor,
    required this.onTap,
    this.distanceLabel,
  });

  final AccessiblePlace place;
  final Color categoryColor;
  final IconData categoryIcon;
  final Color scoreColor;
  final VoidCallback onTap;
  final String? distanceLabel;

  List<IconData> get _featureIcons {
    final icons = <IconData>[];
    void add(bool on, IconData icon) {
      if (on && icons.length < 4) icons.add(icon);
    }

    add(
      place.needs.contains('wheelchair') ||
          place.features.contains(PlaceAmenities.stepFree) ||
          place.features.contains(PlaceAmenities.ramp),
      Icons.accessible_rounded,
    );
    add(place.features.contains(PlaceAmenities.parking), Icons.local_parking);
    add(place.features.contains(PlaceAmenities.hearing), Icons.hearing);
    add(
      place.features.contains(PlaceAmenities.braille) ||
          place.features.contains(PlaceAmenities.visual) ||
          place.needs.contains('visual'),
      Icons.visibility,
    );
    add(place.features.contains(PlaceAmenities.toilet), Icons.wc);
    return icons;
  }

  @override
  Widget build(BuildContext context) {
    final extras = place.features.length + place.needs.length > 4;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 78,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: place.imageUrl.isEmpty
                        ? Container(
                            width: double.infinity,
                            color: AppColors.primaryLight,
                          )
                        : DecodedNetworkImage(
                            place.imageUrl,
                            width: double.infinity,
                            height: 78,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                Container(color: AppColors.primaryLight),
                          ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scoreColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${place.score}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    bottom: -10,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(categoryIcon, size: 11, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              place.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E1B4B),
              ),
            ),
            Text(
              '${distanceLabel ?? place.categoryLabel} · ${place.openNow ? 'Open' : 'Closed'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: place.openNow
                    ? const Color(0xFF16A34A)
                    : AppColors.textSecondary,
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 11,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    '${place.rating.toStringAsFixed(1)} (${place.reviewCount})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 9),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                for (final icon in _featureIcons)
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Icon(icon, size: 12, color: AppColors.primary),
                  ),
                if (extras)
                  const Icon(
                    Icons.more_horiz,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
