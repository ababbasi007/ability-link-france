import 'package:flutter/material.dart';

import '../services/background_task.dart';
import 'home/home_screen.dart';
import 'map/accessibility_map_screen.dart';
import 'profile/profile_screen.dart';
import 'community/community_hub_screen.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/ux_scope.dart';

/// Signed-in tab host. The bottom navigation itself lives in
/// [PersistentNavHost] so it stays visible on every pushed screen too.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _index = 0;

  static const _announceKeys = {
    0: 'home',
    1: 'map',
    3: 'community',
    4: 'profile',
  };

  @override
  void initState() {
    super.initState();
    // Ask for location once when the signed-in shell opens.
    LocationService.instance.ensure();
    runInBackground(NotificationService().syncDueReminders(), 'reminder sync');
    runInBackground(PushService.instance.sync(), 'push token sync');
    AppShellNav.instance.attach(this, index: _index, onSelect: goTab);
  }

  @override
  void dispose() {
    AppShellNav.instance.detach(this);
    super.dispose();
  }

  void openProfileTab() => goTab(4);

  void goTab(int index) {
    if (!mounted) return;
    UxScope.tap(context);
    setState(() => _index = index);
    AppShellNav.instance.syncIndex(index);
    final key = _announceKeys[index];
    if (key != null) {
      UxScope.announce(context, UxScope.copy(context, key));
    }
  }

  int get _stackIndex {
    if (_index == 2) return 0;
    if (_index > 2) return _index - 1;
    return _index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _stackIndex,
        children: const [
          HomeScreen(),
          AccessibilityMapScreen(showBack: false),
          CommunityHubScreen(),
          ProfileScreen(),
        ],
      ),
    );
  }
}
