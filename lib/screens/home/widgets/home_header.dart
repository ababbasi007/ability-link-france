import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/ux_scope.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onMenu,
    required this.onNotifications,
    required this.onProfile,
    this.unreadCount = 0,
    this.photoUrl,
  });

  final VoidCallback onMenu;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final int unreadCount;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 2),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenu,
            tooltip: UxScope.copy(context, 'menu'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.textPrimary,
              size: 26,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/ability_link_logo_a.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/images/logo_a.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, _, _) => Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Ability Link',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onNotifications,
                tooltip: UxScope.copy(context, 'notifications'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onProfile,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                  ? NetworkImage(photoUrl!)
                  : const AssetImage('assets/images/avatar.png'),
              onBackgroundImageError: (_, _) {},
            ),
          ),
        ],
      ),
    );
  }
}

/// Location chip + search field with green search button (matches mockup).
class HomeSearchRow extends StatelessWidget {
  const HomeSearchRow({
    super.key,
    required this.onSearch,
    this.locationLabel = 'Abbottabad, Pakistan',
    this.onLocation,
  });

  final VoidCallback onSearch;
  final String locationLabel;
  final VoidCallback? onLocation;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onLocation ?? onSearch,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 88),
                    child: Text(
                      locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: onSearch,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 42,
                padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.textTertiary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Search services, places, jobs...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onSearch,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
