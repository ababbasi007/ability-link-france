import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_copy.dart';
import '../../models/accessible_routing_prefs.dart';
import '../../models/ux_prefs.dart';
import '../../services/accessible_routing_prefs_store.dart';
import '../../services/auth_service.dart';
import '../../services/background_task.dart';
import '../../services/ux_prefs_service.dart';
import '../../theme/app_colors.dart';

class AccessibilityUxScreen extends StatefulWidget {
  const AccessibilityUxScreen({super.key});

  @override
  State<AccessibilityUxScreen> createState() => _AccessibilityUxScreenState();
}

class _AccessibilityUxScreenState extends State<AccessibilityUxScreen> {
  final _ux = UxPrefsService();
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    runInBackground(_ux.ensureSeeded(), 'seed accessibility prefs');
  }

  Future<void> _save(UxPrefs next) async {
    await _ux.save(next);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _auth.watchCurrentProfile(),
      builder: (context, snap) {
        final prefs = UxPrefs.fromProfile(snap.data);
        final copy = AppCopy.t(prefs, 'accessSettings');
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              copy,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                AppCopy.t(prefs, 'accessSubtitle'),
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _ChecklistCard(prefs: prefs),
              const SizedBox(height: 16),
              Text(
                'Display',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Large text'),
                subtitle: const Text('Boosts size on top of the slider'),
                value: prefs.largeText,
                onChanged: (v) => _save(prefs.copyWith(largeText: v)),
              ),
              Text(
                'Text size',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  const Text('A'),
                  Expanded(
                    child: Slider(
                      value: prefs.textSize,
                      min: 0.8,
                      max: 1.4,
                      divisions: 6,
                      label: prefs.textSize.toStringAsFixed(1),
                      onChanged: (v) => _save(prefs.copyWith(textSize: v)),
                    ),
                  ),
                  const Text('A', style: TextStyle(fontSize: 22)),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('High contrast'),
                subtitle: const Text('Yellow on black for low vision (WCAG)'),
                value: prefs.highContrast,
                onChanged: (v) => _save(prefs.copyWith(highContrast: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark mode'),
                value: prefs.darkMode,
                onChanged: (v) => _save(prefs.copyWith(darkMode: v)),
              ),
              const Divider(),
              Text(
                'Hearing, speech & reading',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Captions'),
                subtitle: const Text('Show spoken words as text at the bottom'),
                value: prefs.captions,
                onChanged: (v) => _save(prefs.copyWith(captions: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Simple language'),
                subtitle: const Text('Shorter words on Home and navigation'),
                value: prefs.simpleLanguage,
                onChanged: (v) => _save(prefs.copyWith(simpleLanguage: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Screen reader voice'),
                subtitle: const Text('Speak labels when you change screens'),
                value: prefs.screenReader,
                onChanged: (v) => _save(prefs.copyWith(screenReader: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Voice navigation'),
                subtitle: const Text(
                  'Speak route steps and use the Home mic for search',
                ),
                value: prefs.voiceNavigation,
                onChanged: (v) => _save(prefs.copyWith(voiceNavigation: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Haptic feedback'),
                value: prefs.hapticFeedback,
                onChanged: (v) => _save(prefs.copyWith(hapticFeedback: v)),
              ),
              const Divider(),
              Text(
                'Transportation',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Preferred travel mode for accessible routing.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const _TransportModeCard(),
              const Divider(),
              Text(
                'Language',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: prefs.language,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'App language',
                ),
                items: [
                  for (final lang in UxPrefs.languages)
                    DropdownMenuItem(value: lang, child: Text(lang)),
                ],
                onChanged: (v) {
                  if (v != null) _save(prefs.copyWith(language: v));
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Arabic uses right-to-left layout. AI tools still translate longer text.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.prefs});

  final UxPrefs prefs;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Text scale ${prefs.effectiveTextScale.toStringAsFixed(2)}×', true),
      ('Contrast', prefs.highContrast),
      ('Captions', prefs.captions),
      ('Simple language', prefs.simpleLanguage),
      ('Screen reader voice', prefs.screenReader),
      ('Language: ${prefs.language}', true),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppCopy.t(prefs, 'wcagTitle'),
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      item.$2 ? Icons.check_circle : Icons.circle_outlined,
                      size: 18,
                      color: item.$2
                          ? AppColors.success
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.$1)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TransportModeCard extends StatefulWidget {
  const _TransportModeCard();

  @override
  State<_TransportModeCard> createState() => _TransportModeCardState();
}

class _TransportModeCardState extends State<_TransportModeCard> {
  AccessibleRoutingPrefs _prefs = AccessibleRoutingPrefs.defaults;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await AccessibleRoutingPrefsStore.instance.load();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _loading = false;
    });
  }

  Future<void> _setMode(PreferredTransportMode mode) async {
    final next = _prefs.copyWith(preferredTransportMode: mode);
    setState(() => _prefs = next);
    await AccessibleRoutingPrefsStore.instance.save(next);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      );
    }
    return SegmentedButton<PreferredTransportMode>(
      segments: [
        for (final mode in PreferredTransportMode.values)
          ButtonSegment(
            value: mode,
            label: Text(mode.label, style: const TextStyle(fontSize: 12)),
            tooltip: switch (mode) {
              PreferredTransportMode.walk => 'Standard walking directions',
              PreferredTransportMode.wheelchair =>
                'Wheelchair / step-free routing when available',
              PreferredTransportMode.transit =>
                'Prefer venues with accessible transit options',
            },
          ),
      ],
      selected: {_prefs.preferredTransportMode},
      onSelectionChanged: (set) {
        if (set.isNotEmpty) _setMode(set.first);
      },
    );
  }
}
