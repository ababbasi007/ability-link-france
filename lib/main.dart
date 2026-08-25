import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'models/ux_prefs.dart';
import 'screens/profile/security_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/push_service.dart';
import 'services/ux_prefs_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/ux_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushService.instance.start();
  runApp(const AbilityLinkApp());
}

class AbilityLinkApp extends StatefulWidget {
  const AbilityLinkApp({super.key});

  @override
  State<AbilityLinkApp> createState() => _AbilityLinkAppState();
}

class _AbilityLinkAppState extends State<AbilityLinkApp> {
  final _auth = AuthService();
  final _ux = UxPrefsService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _auth.watchCurrentProfile(),
      builder: (context, snap) {
        final prefs = UxPrefs.fromProfile(snap.data);
        final biometricLock = snap.data?.preferences['biometricLock'] == true;
        final theme = AppTheme.forPrefs(
          darkMode: prefs.darkMode,
          highContrast: prefs.highContrast,
        );
        return UxScope(
          prefs: prefs,
          service: _ux,
          child: MaterialApp(
            title: 'Ability Link',
            debugShowCheckedModeBanner: false,
            navigatorKey: AppShellNav.navigatorKey,
            locale: prefs.locale,
            supportedLocales: UxPrefs.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: theme,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              final scaled = MediaQuery(
                data: media.copyWith(
                  textScaler: TextScaler.linear(
                    (media.textScaler.scale(100) / 100) *
                        prefs.effectiveTextScale,
                  ),
                  boldText: prefs.largeText || media.boldText,
                  highContrast: prefs.highContrast || media.highContrast,
                ),
                child: BiometricLockGate(
                  enabled: biometricLock,
                  child: PersistentNavHost(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
              return CaptionOverlay(prefs: prefs, child: scaled);
            },
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
