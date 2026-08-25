import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/ai/ai_assistant_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/telehealth/telehealth_screen.dart';
import '../theme/app_colors.dart';
import 'ux_scope.dart';

/// Bridges [MainShell] and the app-wide bottom navigation so the bar stays
/// visible while feature screens are pushed on top of the shell.
class AppShellNav extends ChangeNotifier {
  AppShellNav._();

  static final AppShellNav instance = AppShellNav._();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Object? _shell;
  int _index = 0;
  void Function(int index)? _onSelect;

  bool get active => _shell != null;
  int get index => _index;

  void attach(
    Object shell, {
    required int index,
    required void Function(int index) onSelect,
  }) {
    _shell = shell;
    _index = index;
    _onSelect = onSelect;
    _notifyLater();
  }

  void detach(Object shell) {
    if (_shell != shell) return;
    _shell = null;
    _onSelect = null;
    _notifyLater();
  }

  void syncIndex(int index) {
    if (_index == index) return;
    _index = index;
    _notifyLater();
  }

  /// Returns to the shell before switching tabs, so the tap works from any
  /// pushed screen.
  void select(int index) {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    _onSelect?.call(index);
  }

  // Attach happens during the shell's first build, so listeners must not be
  // notified until that build has finished.
  void _notifyLater() {
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }
}

/// Places [child] above the bottom navigation so no screen can cover it.
class PersistentNavHost extends StatelessWidget {
  const PersistentNavHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppShellNav.instance,
      builder: (context, _) {
        final nav = AppShellNav.instance;
        return Column(
          children: [
            Expanded(
              child: ClipRect(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final media = MediaQuery.of(context);
                    return MediaQuery(
                      data: media.copyWith(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        padding: media.padding.copyWith(bottom: 0),
                        viewPadding: media.viewPadding.copyWith(bottom: 0),
                      ),
                      child: child,
                    );
                  },
                ),
              ),
            ),
            if (nav.active)
              AppBottomNavBar(index: nav.index, onTap: nav.select),
          ],
        );
      },
    );
  }
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  void _openCreateSheet(BuildContext context) {
    UxScope.tap(context);
    final host = AppShellNav.navigatorKey.currentContext ?? context;
    showModalBottomSheet<void>(
      context: host,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        void open(Widget screen) {
          Navigator.pop(sheetContext);
          AppShellNav.navigatorKey.currentState?.push(
            MaterialPageRoute<void>(builder: (_) => screen),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: const Text('Book appointment'),
                  onTap: () => open(const TelehealthScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.place_rounded),
                  title: const Text('Find accessible places'),
                  onTap: () => open(const SearchScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: const Text('Ask AI Assistant'),
                  onTap: () => open(const AiAssistantScreen()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: const Color(0x1A000000),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: UxScope.copy(context, 'home'),
                selected: index == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                label: 'Explore',
                selected: index == 1,
                onTap: () => onTap(1),
              ),
              SizedBox(
                width: 72,
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'Create',
                    child: GestureDetector(
                      onTap: () => _openCreateSheet(context),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x40006D44),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Messages',
                selected: index == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: UxScope.copy(context, 'profile'),
                selected: index == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: color,
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(top: 2),
                height: 3,
                width: selected ? 18 : 0,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
