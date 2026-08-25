import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_lock_service.dart';
import '../../services/places_service.dart';
import '../../services/place_report_service.dart';
import '../../services/profile_media_service.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_gate.dart';
import '../notifications/notifications_inbox_screen.dart';
import '../billing/billing_screen.dart';
import '../accessibility/accessibility_ux_screen.dart';
import '../privacy/passport_edit_screen.dart';
import 'security_screen.dart';

// ── palette ────────────────────────────────────────────────────────────────
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _forest = AppColors.primary;
const _forestLight = Color(0xFFE8F5EE);

TextStyle _ts({
  double size = 13,
  FontWeight weight = FontWeight.w500,
  Color color = _ink,
  double? height,
}) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showBack = false});

  final bool showBack;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _places = PlacesService();
  final _placeReports = PlaceReportService();
  final _media = ProfileMediaService();
  bool _signingOut = false;

  Future<void> _changePhoto() async {
    try {
      final url = await _media.pickFromSheet(context);
      if (url == null || !mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Photo updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _soon(String feature) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$feature — coming soon')));
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign out?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: Text(
          "You'll need to sign in again to access your account.",
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign out',
                style: GoogleFonts.plusJakartaSans(
                    color: AppColors.sos, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _signingOut = true);
    try {
      await _auth.signOut();
      BiometricLockService().lockSession();
      if (!mounted) return;
      resetToAuthGate(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_auth.messageFor(e))));
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Future<void> _openEditor(
    UserProfile profile, {
    PassportEditSection section = PassportEditSection.needs,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PassportEditScreen(profile: profile, initialSection: section),
      ),
    );
  }

  void _onManageTap(String title, UserProfile profile) {
    switch (title) {
      case 'Personal Information':
        _openEditor(profile, section: PassportEditSection.personal);
        return;
      case 'Accessibility Profile':
        _openEditor(profile, section: PassportEditSection.needs);
        return;
      case 'Notifications':
        Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const NotificationsInboxScreen(initialTab: 1)));
        return;
      case 'Privacy & Security':
        Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SecurityScreen()));
        return;
      case 'Payment Methods':
        Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const BillingScreen()));
        return;
      case 'Verified Badges':
        _soon(title);
        return;
      case 'Help Center':
        _soon(title);
        return;
      case 'Send Feedback':
        _soon(title);
        return;
      case 'About Ability Link':
        _soon(title);
        return;
      case 'Log Out':
        _signOut();
        return;
      default:
        _soon(title);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: _auth.watchCurrentProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final loading =
            snapshot.connectionState == ConnectionState.waiting && profile == null;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : profile == null
                    ? Center(
                        child: Text('Sign in to view your profile',
                            style: _ts(color: _muted)))
                    : StreamBuilder<Set<String>>(
                        stream: _places.watchFavoriteIds(),
                        builder: (context, favSnap) {
                          final favCount = favSnap.data?.length ?? 23;
                          return StreamBuilder<List<dynamic>>(
                            stream: _placeReports.watchMine(),
                            builder: (context, repSnap) {
                              final reviewCount = repSnap.data?.length ?? 8;
                              return _ProfileBody(
                                profile: profile,
                                showBack: widget.showBack,
                                savedPlaces: favCount,
                                reviews: reviewCount,
                                signingOut: _signingOut,
                                onBack: () => Navigator.of(context).maybePop(),
                                onNotify: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const NotificationsInboxScreen())),
                                onSettings: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const AccessibilityUxScreen())),
                                onCamera: _changePhoto,
                                onProfileArrow: () => _openEditor(profile,
                                    section: PassportEditSection.personal),
                                onCompleteNow: () => _openEditor(profile),
                                onManageTap: (t) => _onManageTap(t, profile),
                              );
                            },
                          );
                        },
                      ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pure-display body widget — no business logic
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.showBack,
    required this.savedPlaces,
    required this.reviews,
    required this.signingOut,
    required this.onBack,
    required this.onNotify,
    required this.onSettings,
    required this.onCamera,
    required this.onProfileArrow,
    required this.onCompleteNow,
    required this.onManageTap,
  });

  final UserProfile profile;
  final bool showBack;
  final int savedPlaces;
  final int reviews;
  final bool signingOut;
  final VoidCallback onBack;
  final VoidCallback onNotify;
  final VoidCallback onSettings;
  final VoidCallback onCamera;
  final VoidCallback onProfileArrow;
  final VoidCallback onCompleteNow;
  final ValueChanged<String> onManageTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AppBar(
                    showBack: showBack,
                    onBack: onBack,
                    onNotify: onNotify,
                    onSettings: onSettings,
                  ),
                  const SizedBox(height: 6),
                  _ProfileCard(
                    profile: profile,
                    onCamera: onCamera,
                    onArrow: onProfileArrow,
                  ),
                  const SizedBox(height: 6),
                  _StatsRow(
                    savedPlaces: savedPlaces,
                    following: 12,
                    reviews: reviews,
                    bookings: 5,
                  ),
                  const SizedBox(height: 6),
                  _CompleteBanner(
                    percent: profile.profileStrengthPercent,
                    onTap: onCompleteNow,
                  ),
                  const SizedBox(height: 8),
                  Text('Manage My Account',
                      style: _ts(size: 13, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  _MenuSection(
                    items: const [
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Personal Information',
                        subtitle: 'Update your personal details',
                      ),
                      _MenuItem(
                        icon: Icons.accessible_rounded,
                        title: 'Accessibility Profile',
                        subtitle: 'Manage your accessibility needs',
                      ),
                      _MenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle: 'Manage your notification preferences',
                      ),
                      _MenuItem(
                        icon: Icons.lock_outline_rounded,
                        title: 'Privacy & Security',
                        subtitle: 'Manage privacy settings and security',
                      ),
                      _MenuItem(
                        icon: Icons.credit_card_rounded,
                        title: 'Payment Methods',
                        subtitle: 'Manage your cards and wallets',
                      ),
                      _MenuItem(
                        icon: Icons.verified_outlined,
                        title: 'Verified Badges',
                        subtitle: 'Your verifications and badges',
                      ),
                    ],
                    onTap: onManageTap,
                  ),
                  const SizedBox(height: 8),
                  Text('More Options',
                      style: _ts(size: 13, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  _MenuSection(
                    items: const [
                      _MenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help Center',
                        subtitle: 'Get help and support',
                      ),
                      _MenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Send Feedback',
                        subtitle: 'Share your thoughts with us',
                      ),
                      _MenuItem(
                        icon: Icons.info_outline_rounded,
                        title: 'About Ability Link',
                        subtitle: 'Learn more about the app',
                      ),
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        title: 'Log Out',
                        subtitle: 'Sign out from your account',
                        isDestructive: true,
                      ),
                    ],
                    onTap: onManageTap,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar — logo left, "Profile" centre, bell + gear right
// ─────────────────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.showBack,
    required this.onBack,
    required this.onNotify,
    required this.onSettings,
  });

  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onNotify;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 0, 0),
      child: Row(
        children: [
          if (showBack)
            _TinyIconBtn(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack,
            )
          else ...[
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _forest,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: Colors.white, size: 15),
            ),
            const SizedBox(width: 5),
            Text('Ability Link',
                style: _ts(size: 12.5, weight: FontWeight.w800, color: _forest)),
          ],
          const Spacer(),
          Text('Profile',
              style: _ts(size: 15, weight: FontWeight.w800, color: _ink)),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _TinyIconBtn(
                icon: Icons.notifications_none_rounded,
                onTap: onNotify,
              ),
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _forest,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          _TinyIconBtn(
            icon: Icons.settings_outlined,
            onTap: onSettings,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile card — avatar + info + chevron
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onCamera,
    required this.onArrow,
  });

  final UserProfile profile;
  final VoidCallback onCamera;
  final VoidCallback onArrow;

  @override
  Widget build(BuildContext context) {
    final photo = profile.photoUrl;
    final name = profile.displayName;
    final handle =
        '@${name.toLowerCase().replaceAll(' ', '')}';

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _forestLight,
                backgroundImage: photo != null && photo.isNotEmpty
                    ? NetworkImage(photo) as ImageProvider
                    : const AssetImage('assets/images/avatar.png'),
                onBackgroundImageError: (_, _) {},
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: onCamera,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: _forest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 10, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _ts(
                              size: 14.5,
                              weight: FontWeight.w800,
                              color: _ink)),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.verified_rounded,
                        size: 14, color: _forest),
                  ],
                ),
                Text(handle, style: _ts(size: 11, color: _muted)),
                const SizedBox(height: 3),
                _IconRow(Icons.location_on_outlined,
                    profile.city.isEmpty ? 'Abbottabad, Pakistan' : profile.city),
                const SizedBox(height: 1),
                _IconRow(Icons.calendar_today_outlined,
                    'Member since ${profile.memberSinceLabel}'),
                const SizedBox(height: 1),
                _IconRow(Icons.verified_outlined, 'Verified Account',
                    color: _forest),
              ],
            ),
          ),
          GestureDetector(
            onTap: onArrow,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.chevron_right_rounded, color: _muted, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow(this.icon, this.text, {this.color = _muted});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _ts(size: 10.5, color: color)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row — 4 tiles
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.savedPlaces,
    required this.following,
    required this.reviews,
    required this.bookings,
  });

  final int savedPlaces;
  final int following;
  final int reviews;
  final int bookings;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.bookmark_outline_rounded, '$savedPlaces', 'Saved Places'),
      (Icons.favorite_border_rounded, '$following', 'Following'),
      (Icons.star_border_rounded, '$reviews', 'Reviews'),
      (Icons.calendar_month_outlined, '$bookings', 'Bookings'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: _forestLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(items[i].$1, color: _forest, size: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(items[i].$2,
                      style: _ts(
                          size: 15, weight: FontWeight.w800, color: _ink)),
                  Text(items[i].$3,
                      style: _ts(size: 9, color: _muted),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
            if (i < items.length - 1)
              Container(width: 1, height: 32, color: _border),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Complete profile banner
// ─────────────────────────────────────────────────────────────────────────────

class _CompleteBanner extends StatelessWidget {
  const _CompleteBanner({required this.percent, required this.onTap});

  final int percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = percent.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: _forestLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _forest.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _forest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Complete Your Profile',
                    style: _ts(
                        size: 12, weight: FontWeight.w800, color: _forest)),
                Text(
                  'Add a few more details to get better recommendations.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _ts(size: 10, color: _muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(38, 38),
                  painter: _RingPainter(pct / 100),
                ),
                Text('$pct%',
                    style: _ts(
                        size: 10, weight: FontWeight.w800, color: _forest)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Complete Now',
                  style: _ts(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 4;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Track
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = AppColors.primary.withValues(alpha: 0.18),
    );
    // Progress
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value;
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu section — vertical list of tappable rows
// ─────────────────────────────────────────────────────────────────────────────

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.items, required this.onTap});

  final List<_MenuItem> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: _border),
            _MenuRow(item: items[i], onTap: () => onTap(items[i].title)),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.onTap});

  final _MenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor =
        item.isDestructive ? AppColors.sos : _ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: item.isDestructive
                    ? AppColors.sos.withValues(alpha: 0.08)
                    : _forestLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                size: 15,
                color: item.isDestructive ? AppColors.sos : _forest,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: _ts(
                          size: 12,
                          weight: FontWeight.w700,
                          color: titleColor)),
                  Text(item.subtitle, style: _ts(size: 10, color: _muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _TinyIconBtn extends StatelessWidget {
  const _TinyIconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: _ink, size: 20),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
