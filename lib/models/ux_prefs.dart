import 'package:flutter/material.dart';

import 'user_profile.dart';

class UxPrefs {
  const UxPrefs({
    this.largeText = false,
    this.voiceNavigation = false,
    this.darkMode = false,
    this.highContrast = false,
    this.screenReader = false,
    this.hapticFeedback = true,
    this.captions = true,
    this.simpleLanguage = false,
    this.textSize = 1.0,
    this.language = 'English',
  });

  final bool largeText;
  final bool voiceNavigation;
  final bool darkMode;
  final bool highContrast;
  final bool screenReader;
  final bool hapticFeedback;
  final bool captions;
  final bool simpleLanguage;
  final double textSize;
  final String language;

  static const languages = ['English', 'French', 'Arabic', 'Spanish'];

  static const supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
    Locale('es'),
  ];

  double get effectiveTextScale {
    final bump = largeText ? 1.12 : 1.0;
    return (textSize * bump).clamp(0.85, 1.6);
  }

  Locale get locale => switch (language) {
    'French' => const Locale('fr'),
    'Arabic' => const Locale('ar'),
    'Spanish' => const Locale('es'),
    _ => const Locale('en'),
  };

  String get ttsCode => switch (language) {
    'French' => 'fr-FR',
    'Arabic' => 'ar-SA',
    'Spanish' => 'es-ES',
    _ => 'en-US',
  };

  String get sttLocale => switch (language) {
    'French' => 'fr_FR',
    'Arabic' => 'ar_SA',
    'Spanish' => 'es_ES',
    _ => 'en_US',
  };

  ThemeMode get themeMode {
    if (highContrast) return ThemeMode.light;
    return darkMode ? ThemeMode.dark : ThemeMode.light;
  }

  factory UxPrefs.fromProfile(UserProfile? profile) {
    if (profile == null) return const UxPrefs();
    return UxPrefs.fromMaps(profile.preferences, profile.personal);
  }

  factory UxPrefs.fromMaps(
    Map<String, dynamic> preferences,
    Map<String, dynamic> personal,
  ) {
    bool flag(String k, bool fallback) {
      final v = preferences[k];
      if (v == null) return fallback;
      return v == true;
    }

    final sizeRaw = preferences['textSize'];
    final size = sizeRaw is num ? sizeRaw.toDouble() : 1.0;
    final lang =
        (preferences['uiLanguage'] as String?)?.trim().isNotEmpty == true
        ? preferences['uiLanguage'] as String
        : ((personal['preferredLanguage'] as String?)?.trim().isNotEmpty == true
              ? personal['preferredLanguage'] as String
              : 'English');
    return UxPrefs(
      largeText: flag('largeText', false),
      voiceNavigation: flag('voiceNavigation', false),
      darkMode: flag('darkMode', false),
      highContrast: flag('highContrast', false),
      screenReader: flag('screenReader', false),
      hapticFeedback: flag('hapticFeedback', true),
      captions: flag('captions', true),
      simpleLanguage: flag('simpleLanguage', false),
      textSize: size.clamp(0.8, 1.4),
      language: languages.contains(lang) ? lang : 'English',
    );
  }

  Map<String, dynamic> toPreferencesMap() => {
    'largeText': largeText,
    'voiceNavigation': voiceNavigation,
    'darkMode': darkMode,
    'highContrast': highContrast,
    'screenReader': screenReader,
    'hapticFeedback': hapticFeedback,
    'captions': captions,
    'simpleLanguage': simpleLanguage,
    'textSize': textSize,
    'uiLanguage': language,
  };

  UxPrefs copyWith({
    bool? largeText,
    bool? voiceNavigation,
    bool? darkMode,
    bool? highContrast,
    bool? screenReader,
    bool? hapticFeedback,
    bool? captions,
    bool? simpleLanguage,
    double? textSize,
    String? language,
  }) {
    return UxPrefs(
      largeText: largeText ?? this.largeText,
      voiceNavigation: voiceNavigation ?? this.voiceNavigation,
      darkMode: darkMode ?? this.darkMode,
      highContrast: highContrast ?? this.highContrast,
      screenReader: screenReader ?? this.screenReader,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      captions: captions ?? this.captions,
      simpleLanguage: simpleLanguage ?? this.simpleLanguage,
      textSize: textSize ?? this.textSize,
      language: language ?? this.language,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UxPrefs &&
        other.largeText == largeText &&
        other.voiceNavigation == voiceNavigation &&
        other.darkMode == darkMode &&
        other.highContrast == highContrast &&
        other.screenReader == screenReader &&
        other.hapticFeedback == hapticFeedback &&
        other.captions == captions &&
        other.simpleLanguage == simpleLanguage &&
        other.textSize == textSize &&
        other.language == language;
  }

  @override
  int get hashCode => Object.hash(
    largeText,
    voiceNavigation,
    darkMode,
    highContrast,
    screenReader,
    hapticFeedback,
    captions,
    simpleLanguage,
    textSize,
    language,
  );
}
