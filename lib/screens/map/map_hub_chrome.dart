import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/place.dart';
import '../../theme/app_colors.dart';

/// Mockup-matching chrome for the Accessibility Map hub layout.
class MapHubHeader extends StatelessWidget {
  const MapHubHeader({
    super.key,
    required this.showBack,
    required this.onBack,
    required this.locationLabel,
    required this.onLocation,
    required this.onNotify,
  });

  final bool showBack;
  final VoidCallback onBack;
  final String locationLabel;
  final VoidCallback onLocation;
  final VoidCallback onNotify;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
              visualDensity: VisualDensity.compact,
            )
          else
            const SizedBox(width: 12),
          Image.asset(
            'assets/images/ability_link_logo_a.png',
            width: 26,
            height: 26,
            errorBuilder: (_, _, _) => Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: const Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Ability ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: 'Link',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onLocation,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 108),
                    child: Text(
                      locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onNotify,
                icon: const Icon(Icons.notifications_none_rounded, size: 22),
                visualDensity: VisualDensity.compact,
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MapHubHero extends StatelessWidget {
  const MapHubHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 4, 0),
      child: SizedBox(
        height: 108,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Accessibility Map',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore accessible places around you.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 0.86,
                child: Image.asset(
                  'assets/images/map_hero_art.png',
                  width: 138,
                  height: 108,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.accessible_forward_rounded,
                    size: 72,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapHubSearchBar extends StatelessWidget {
  const MapHubSearchBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onFilter,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilter;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: InputDecoration(
                hintText:
                    'Search for places (e.g. hospital, restaurant, bank...)',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            onPressed: onFilter,
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF111827)),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class MapHubCategoryChip extends StatelessWidget {
  const MapHubCategoryChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.fg,
    this.parkingBadge = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color fg;
  final bool parkingBadge;

  @override
  Widget build(BuildContext context) {
    final wide = label.contains(' ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: wide ? 88 : 72,
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.08 : 0.04),
              blurRadius: selected ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (parkingBadge)
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : const Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'P',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? AppColors.primary : Colors.white,
                  ),
                ),
              )
            else
              Icon(icon, color: selected ? Colors.white : fg, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textPrimary,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapHubNearbyCard extends StatelessWidget {
  const MapHubNearbyCard({
    super.key,
    required this.place,
    required this.distanceLabel,
    required this.iconColor,
    required this.icon,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  final AccessiblePlace place;
  final String distanceLabel;
  final Color iconColor;
  final IconData icon;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  static const _short = <String, String>{
    'wheelchair': 'Wheelchair Access',
    PlaceAmenities.elevator: 'Elevator',
    PlaceAmenities.toilet: 'Accessible Restroom',
    PlaceAmenities.stepFree: 'Accessible Entrance',
    PlaceAmenities.ramp: 'Accessible Entrance',
    PlaceAmenities.parking: 'Accessible Parking',
  };

  List<String> get _tags {
    final tags = <String>[];
    void add(String key) {
      final label = _short[key] ?? PlaceAmenities.label(key);
      if (label.isEmpty || tags.contains(label)) return;
      tags.add(label);
    }

    if (place.needs.contains('wheelchair')) add('wheelchair');
    for (final f in place.features) {
      add(f);
    }
    return tags;
  }

  String get _hoursLabel {
    if (place.isAlwaysOpen) return '24/7 Open';
    if (place.hours.trim().isNotEmpty) {
      return place.hours.startsWith('Open')
          ? place.hours
          : 'Open ${place.hours}';
    }
    return place.openNow || place.isOpenNow() ? 'Open now' : 'Closed';
  }

  bool get _hoursOpen {
    if (place.isAlwaysOpen) return true;
    return place.openNow || place.isOpenNow();
  }

  @override
  Widget build(BuildContext context) {
    final tags = _tags;
    final shown = tags.take(2).toList();
    final extra = tags.length - shown.length;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECEB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (distanceLabel.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 6, top: 2),
                            child: Text(
                              distanceLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${place.categoryLabel}  ·  ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextSpan(
                            text: _hoursLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _hoursOpen
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (final tag in shown) _TagPill(label: tag),
                              if (extra > 0)
                                _TagPill(label: '+$extra', muted: true),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: onFavorite,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          icon: Icon(
                            isFavorite
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: isFavorite
                                ? AppColors.primary
                                : const Color(0xFF9CA3AF),
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
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFF3F4F6) : const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: muted ? AppColors.textSecondary : AppColors.primary,
        ),
      ),
    );
  }
}

class MapHubAddPlaceBanner extends StatelessWidget {
  const MapHubAddPlaceBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Can't find a place?",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Help others by adding new places and improving accessibility information.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add a Place',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapHubStatusChip extends StatelessWidget {
  const MapHubStatusChip({super.key, required this.onLongPress});

  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              'Showing accessible places near you',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapHubRoundFab extends StatelessWidget {
  const MapHubRoundFab({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: const Color(0xFF111827)),
        ),
      ),
    );
  }
}
