import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_profile.dart';
import '../../services/ai_tools_service.dart';
import '../../services/auth_service.dart';
import '../../services/voice_service.dart';
import '../../theme/app_colors.dart';

class AiToolsScreen extends StatefulWidget {
  const AiToolsScreen({super.key, this.initialTool});

  final AiToolKind? initialTool;

  @override
  State<AiToolsScreen> createState() => _AiToolsScreenState();
}

class _AiToolsScreenState extends State<AiToolsScreen> {
  final _tools = AiToolsService();
  final _auth = AuthService();
  final _voice = VoiceService.instance;
  final _input = TextEditingController();
  final _picker = ImagePicker();

  UserProfile? _profile;
  AiToolKind _selected = AiToolKind.placeSummary;
  String _targetLang = 'English';
  bool _busy = false;
  AiToolResult? _result;
  bool _listening = false;

  static const _langs = [
    'English',
    'French',
    'Spanish',
    'Arabic',
    'Urdu',
    'Hindi',
    'German',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTool != null) _selected = widget.initialTool!;
    _auth.getCurrentProfile().then((p) {
      if (!mounted) return;
      setState(() {
        _profile = p;
        if (p?.preferredLanguage != null &&
            _langs.contains(p!.preferredLanguage)) {
          _targetLang = p.preferredLanguage;
        }
      });
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _voice.stopListening();
    _voice.stopSpeaking();
    super.dispose();
  }

  String get _hint {
    switch (_selected) {
      case AiToolKind.placeSummary:
        return 'Optional note (e.g. cafe near me) — or just run';
      case AiToolKind.plainLanguage:
        return 'Paste complex text to simplify…';
      case AiToolKind.translate:
        return 'Text to translate…';
      case AiToolKind.checklist:
        return 'Situation (e.g. hospital visit, airport trip)…';
      case AiToolKind.ocr:
        return 'Or paste text if you prefer not to use camera…';
      case AiToolKind.scorePrediction:
        return 'Optional place hint — or run to score the nearest / unrated place';
      case AiToolKind.recommendations:
        return 'Optional focus (e.g. cafe, hospital) — or run for Passport picks';
      case AiToolKind.routePlan:
        return 'Where to go? (e.g. physiotherapy, library, cafe)…';
    }
  }

  Future<void> _run() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      late AiToolResult result;
      switch (_selected) {
        case AiToolKind.placeSummary:
          result = await _tools.summarizeNearestPlace(profile: _profile);
        case AiToolKind.plainLanguage:
          result = await _tools.toPlainLanguage(_input.text, profile: _profile);
        case AiToolKind.translate:
          result = await _tools.translate(
            _input.text,
            targetLanguage: _targetLang,
            profile: _profile,
          );
        case AiToolKind.checklist:
          result = await _tools.generateChecklist(
            situation: _input.text,
            profile: _profile,
          );
        case AiToolKind.ocr:
          if (_input.text.trim().isNotEmpty) {
            result = await _tools.toPlainLanguage(
              _input.text,
              profile: _profile,
            );
          } else {
            result = const AiToolResult(
              title: 'OCR + plain language',
              text: 'Pick a photo first (camera or gallery).',
              usedLiveModel: false,
            );
          }
        case AiToolKind.scorePrediction:
          result = await _tools.predictNearestAccessibilityScore(
            profile: _profile,
          );
        case AiToolKind.recommendations:
          result = await _tools.personalizedRecommendations(profile: _profile);
        case AiToolKind.routePlan:
          result = await _tools.planAccessibleRoute(
            query: _input.text,
            profile: _profile,
          );
      }
      if (!mounted) return;
      setState(() => _result = result);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAndOcr(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      _busy = true;
      _result = null;
      _selected = AiToolKind.ocr;
    });
    try {
      final bytes = await file.readAsBytes();
      final mime =
          file.mimeType ??
          (file.path.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg');
      final result = await _tools.ocrImage(
        bytes: bytes,
        mimeType: mime,
        profile: _profile,
      );
      if (!mounted) return;
      setState(() => _result = result);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dictate() async {
    if (_listening) {
      await _voice.stopListening();
      setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    final text = await _voice.listenOnce();
    if (!mounted) return;
    setState(() => _listening = false);
    if (text == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not hear speech. Check mic permission.'),
        ),
      );
      return;
    }
    setState(() {
      _input.text = text;
      _input.selection = TextSelection.collapsed(offset: text.length);
    });
  }

  Future<void> _speakResult() async {
    final text = _result?.text;
    if (text == null || text.isEmpty) return;
    await _voice.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'AI Accessibility Tools',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: _listening ? 'Stop' : 'Dictate',
            onPressed: _dictate,
            icon: Icon(
              _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _listening ? AppColors.sos : AppColors.primary,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            'Tools that make information easier to use.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tool in AiToolKind.values)
                ChoiceChip(
                  selected: _selected == tool,
                  label: Text(_label(tool)),
                  onSelected: (_) => setState(() {
                    _selected = tool;
                    _result = null;
                  }),
                  selectedColor: AppColors.primary,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _selected == tool
                        ? Colors.white
                        : const Color(0xFF1E1B4B),
                  ),
                  backgroundColor: Colors.white,
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selected == AiToolKind.translate)
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _targetLang,
              decoration: InputDecoration(
                labelText: 'Translate to',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                for (final l in _langs)
                  DropdownMenuItem(value: l, child: Text(l)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _targetLang = v);
              },
            ),
          if (_selected == AiToolKind.translate) const SizedBox(height: 12),
          if (_selected == AiToolKind.ocr) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _pickAndOcr(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _pickAndOcr(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _input,
            minLines: _selected == AiToolKind.placeSummary ? 2 : 4,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: _hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _run,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _cta(_selected),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0F1F3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _result!.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E1B4B),
                          ),
                        ),
                      ),
                      Text(
                        _result!.usedLiveModel ? 'Gemini' : 'Local',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    _result!.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.45,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _result!.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy'),
                      ),
                      TextButton.icon(
                        onPressed: _speakResult,
                        icon: const Icon(Icons.volume_up_rounded, size: 16),
                        label: const Text('Listen'),
                      ),
                      TextButton.icon(
                        onPressed: () => _voice.stopSpeaking(),
                        icon: const Icon(Icons.stop_rounded, size: 16),
                        label: const Text('Stop'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _label(AiToolKind kind) {
    switch (kind) {
      case AiToolKind.placeSummary:
        return 'Place summary';
      case AiToolKind.plainLanguage:
        return 'Plain language';
      case AiToolKind.translate:
        return 'Translate';
      case AiToolKind.checklist:
        return 'Checklist';
      case AiToolKind.ocr:
        return 'OCR';
      case AiToolKind.scorePrediction:
        return 'AI score';
      case AiToolKind.recommendations:
        return 'For you';
      case AiToolKind.routePlan:
        return 'Route plan';
    }
  }

  String _cta(AiToolKind kind) {
    switch (kind) {
      case AiToolKind.placeSummary:
        return 'Summarize nearest place';
      case AiToolKind.plainLanguage:
        return 'Simplify text';
      case AiToolKind.translate:
        return 'Translate';
      case AiToolKind.checklist:
        return 'Generate checklist';
      case AiToolKind.ocr:
        return 'Simplify pasted text';
      case AiToolKind.scorePrediction:
        return 'Predict accessibility score';
      case AiToolKind.recommendations:
        return 'Get personalized recommendations';
      case AiToolKind.routePlan:
        return 'Plan accessible route';
    }
  }
}
