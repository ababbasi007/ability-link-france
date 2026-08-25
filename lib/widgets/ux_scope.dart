import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_copy.dart';
import '../models/ux_prefs.dart';
import '../services/ux_prefs_service.dart';
import '../services/voice_service.dart';

class CaptionBus {
  CaptionBus._();
  static final ValueNotifier<String> line = ValueNotifier<String>('');

  static void set(String text) {
    line.value = text.trim();
  }

  static void clear() {
    line.value = '';
  }
}

class UxScope extends InheritedWidget {
  const UxScope({
    super.key,
    required this.prefs,
    required this.service,
    required super.child,
  });

  final UxPrefs prefs;
  final UxPrefsService service;

  static UxScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<UxScope>();
  }

  static UxScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'UxScope not found');
    return scope!;
  }

  static String copy(BuildContext context, String key) {
    final prefs = maybeOf(context)?.prefs ?? const UxPrefs();
    return AppCopy.t(prefs, key);
  }

  static Future<void> tap(BuildContext context) async {
    final prefs = maybeOf(context)?.prefs;
    if (prefs?.hapticFeedback == true) {
      await HapticFeedback.selectionClick();
    }
  }

  static Future<void> announce(BuildContext context, String message) async {
    final prefs = maybeOf(context)?.prefs ?? const UxPrefs();
    if (message.trim().isEmpty) return;
    final dir = prefs.locale.languageCode == 'ar'
        ? TextDirection.rtl
        : TextDirection.ltr;
    SemanticsService.sendAnnouncement(View.of(context), message, dir);
    if (prefs.screenReader || prefs.voiceNavigation) {
      await VoiceService.instance.speak(message, languageCode: prefs.ttsCode);
    }
  }

  @override
  bool updateShouldNotify(UxScope oldWidget) => prefs != oldWidget.prefs;
}

class CaptionOverlay extends StatelessWidget {
  const CaptionOverlay({super.key, required this.prefs, required this.child});

  final UxPrefs prefs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!prefs.captions) return child;
    return Stack(
      children: [
        child,
        Positioned(
          left: 12,
          right: 12,
          bottom: 72,
          child: SafeArea(
            top: false,
            child: ValueListenableBuilder<String>(
              valueListenable: CaptionBus.line,
              builder: (context, live, _) {
                if (live.trim().isEmpty) {
                  return const SizedBox.shrink();
                }
                return Semantics(
                  liveRegion: true,
                  label: live,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        live,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFFFF59D),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
