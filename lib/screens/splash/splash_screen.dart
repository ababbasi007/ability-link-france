import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/auth_gate.dart';
import '../auth/login_screen.dart';
import '../signup/create_account_screen.dart';

const _forest = Color(0xFF006D44);
const _emerald = Color(0xFF00A669);
const _mint = Color(0xFFD5F2E8);
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _controller = PageController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _controller,
        children: [
          _WelcomePage(
            onSkip: () => _go(const AuthGate()),
            onNext: () => _controller.nextPage(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            ),
          ),
          _OnboardPage(
            skip: () => _go(const AuthGate()),
            image: 'assets/images/onboarding_places_scene.png',
            badge: Icons.location_on_rounded,
            title: 'Find Accessible Places',
            body:
                'Discover wheelchair friendly places, services and routes around you.',
            activeDot: 1,
          ),
          _OnboardPage(
            skip: () => _go(const AuthGate()),
            image: 'assets/images/onboarding_services_scene.png',
            badge: Icons.groups_rounded,
            title: 'Connect to Services',
            body:
                'Get support, resources and opportunities that make everyday life easier.',
            activeDot: 2,
          ),
          _TogetherPage(
            onSkip: () => _go(const AuthGate()),
            onGetStarted: () => _go(const CreateAccountScreen()),
            onLogin: () => _go(const LoginScreen()),
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onSkip, required this.onNext});

  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return GestureDetector(
      onTap: onNext,
      child: ColoredBox(
        color: Colors.white,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/splash_screen.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
            ),
            Positioned(
              top: topInset + 4,
              right: 8,
              child: _SkipButton(onPressed: onSkip),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.skip,
    required this.image,
    required this.badge,
    required this.title,
    required this.body,
    required this.activeDot,
  });

  final VoidCallback skip;
  final String image;
  final IconData badge;
  final String title;
  final String body;
  final int activeDot;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _SkipButton(onPressed: skip),
            ),
            Expanded(
              child: Image.asset(
                image,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            _MintBadge(icon: badge),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
            ),
            const SizedBox(height: 28),
            _Dots(active: activeDot, count: 4),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _TogetherPage extends StatelessWidget {
  const _TogetherPage({
    required this.onSkip,
    required this.onGetStarted,
    required this.onLogin,
  });

  final VoidCallback onSkip;
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _SkipButton(onPressed: onSkip),
            ),
            Expanded(
              child: Image.asset(
                'assets/images/onboarding_together_scene.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const _MintBadge(icon: Icons.volunteer_activism_rounded),
            const SizedBox(height: 18),
            Text(
              'Empower Together',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Join a community that believes in inclusion, equality and empowerment for all.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
            ),
            const SizedBox(height: 22),
            const _Dots(active: 3, count: 4),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: onGetStarted,
                style: FilledButton.styleFrom(
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Get Started'),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onLogin,
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                  children: const [
                    TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Login',
                      style: TextStyle(
                        color: _emerald,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onPressed, this.onDark = false});

  final VoidCallback onPressed;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: onDark ? Colors.white : _emerald,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        'Skip',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _MintBadge extends StatelessWidget {
  const _MintBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(color: _mint, shape: BoxShape.circle),
      child: Icon(icon, color: _forest, size: 28),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.active, required this.count, this.onDark = false});

  final int active;
  final int count;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: selected ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: onDark
                ? (selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35))
                : (selected ? _emerald : const Color(0xFFD1D5DB)),
          ),
        );
      }),
    );
  }
}
