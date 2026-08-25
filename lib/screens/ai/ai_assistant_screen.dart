import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/ai_action.dart';
import '../../models/ai_safety.dart';
import '../../models/chat_message.dart';
import '../../models/transport_option.dart';
import '../../models/user_profile.dart';
import '../../services/ai_assistant_service.dart';
import '../../services/ai_tools_service.dart';
import '../../services/auth_service.dart';
import '../../services/trust_service.dart';
import '../../services/voice_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/book_appointment_sheet.dart';
import '../assistance/assistance_booking_sheet.dart';
import '../assistance/assistance_marketplace_screen.dart';
import '../benefits/benefits_hub_screen.dart';
import '../caregiver/caregiver_hub_screen.dart';
import '../education/education_hub_screen.dart';
import '../emergency/emergency_screen.dart';
import '../healthcare/appointments_screen.dart';
import '../map/accessibility_map_screen.dart';
import '../providers/provider_profile_screen.dart';
import '../providers/providers_directory_screen.dart';
import '../search/search_screen.dart';
import '../tele_rehab/tele_rehab_screen.dart';
import '../telehealth/telehealth_screen.dart';
import '../transport/step_free_route_screen.dart';
import '../transport/transport_hub_screen.dart';
import '../travel/travel_hub_screen.dart';
import 'ai_tools_screen.dart';
import '../../services/providers_service.dart';
import '../../data/disability_rights.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key, this.initialPrompt});

  final String? initialPrompt;

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _auth = AuthService();
  final _ai = AiAssistantService();
  final _voice = VoiceService.instance;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();

  final List<ChatMessage> _messages = [];
  UserProfile? _profile;
  bool _loadingProfile = true;
  bool _sending = false;
  bool _showDiscover = true;
  bool _listening = false;

  static const _prompts = [
    (
      Icons.location_on_rounded,
      'Find accessible restaurants near me',
      Color(0xFF6C63FF),
      Color(0xFFEEF0FF),
    ),
    (
      Icons.medical_services_rounded,
      'Find doctors available now',
      Color(0xFF3B82F6),
      Color(0xFFE8F1FF),
    ),
    (
      Icons.directions_walk_rounded,
      'Step-free route to the nearest metro',
      Color(0xFF22C55E),
      Color(0xFFE8F8EF),
    ),
    (
      Icons.account_balance_rounded,
      'What government benefits am I eligible for?',
      Color(0xFFF59E0B),
      Color(0xFFFFF7E8),
    ),
    (
      Icons.gavel_rounded,
      'Explain my disability rights at work',
      Color(0xFF8B5CF6),
      Color(0xFFF3EEFF),
    ),
    (
      Icons.emergency_rounded,
      'What should I do in an accessibility emergency?',
      Color(0xFFE11D48),
      Color(0xFFFFF1F3),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final profile = await _auth.getCurrentProfile();
    final history = await _ai.loadRecent();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loadingProfile = false;
      if (history.isNotEmpty) {
        _messages.addAll(history);
        _showDiscover = false;
      }
    });
    final initial = widget.initialPrompt?.trim();
    if (initial != null && initial.isNotEmpty) {
      await _send(initial);
    }
  }

  @override
  void dispose() {
    _voice.stopListening();
    _voice.stopSpeaking();
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _dictate() async {
    if (_listening) {
      await _voice.stopListening();
      if (mounted) setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    final text = await _voice.listenOnce();
    if (!mounted) return;
    setState(() => _listening = false);
    if (text == null || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No speech detected. Check microphone permission.'),
        ),
      );
      return;
    }
    setState(() {
      _input.text = text;
      _input.selection = TextSelection.collapsed(offset: text.length);
    });
    await _send(text);
  }

  void _openTools([AiToolKind? tool]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AiToolsScreen(initialTool: tool)),
    );
  }

  void _onTool(String label) {
    switch (label) {
      case 'Accessible Route Planner':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AccessibilityMapScreen(),
          ),
        );
        return;
      case 'Place Accessibility Checker':
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen()));
        return;
      case 'Place Summarizer':
        _openTools(AiToolKind.placeSummary);
        return;
      case 'Plain Language':
        _openTools(AiToolKind.plainLanguage);
        return;
      case 'Translate':
        _openTools(AiToolKind.translate);
        return;
      case 'Checklist Generator':
        _openTools(AiToolKind.checklist);
        return;
      case 'OCR / Read Sign':
        _openTools(AiToolKind.ocr);
        return;
      case 'AI Score Prediction':
        _openTools(AiToolKind.scorePrediction);
        return;
      case 'Recommendations for You':
        _openTools(AiToolKind.recommendations);
        return;
      case 'Accessible Route Plan':
        _openTools(AiToolKind.routePlan);
        return;
      case 'All AI Tools':
        _openTools();
        return;
      case 'Emergency Help Guide':
        _send('What should I do in an accessibility emergency?');
        return;
      case 'Find doctors':
        _send('Find doctors near me');
        return;
      case 'Government benefits':
        _send('What government benefits am I eligible for?');
        return;
      default:
        _send(label);
    }
  }

  Future<void> _runAction(AiAction action) async {
    switch (action.type) {
      case AiActionType.map:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AccessibilityMapScreen(),
          ),
        );
      case AiActionType.search:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen()));
      case AiActionType.providers:
        final cat = action.payload['category'] ?? 'All';
        if (cat == 'Caregiving' || cat == 'Assistance') {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AssistanceMarketplaceScreen(),
            ),
          );
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  ProvidersDirectoryScreen(initialCategory: cat, title: cat),
            ),
          );
        }
      case AiActionType.providerProfile:
      case AiActionType.bookProvider:
        final id = action.payload['providerId'] ?? '';
        if (id.isEmpty) return;
        if (action.type == AiActionType.bookProvider) {
          final provider = await ProvidersService().getProvider(id);
          if (!mounted || provider == null) return;
          if (provider.isAssistance) {
            await showAssistanceBookingSheet(context, provider: provider);
          } else {
            await BookAppointmentSheet.show(context, provider: provider);
          }
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProviderProfileScreen(providerId: id),
            ),
          );
        }
      case AiActionType.telehealth:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TelehealthScreen()),
        );
      case AiActionType.rehab:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TeleRehabScreen()),
        );
      case AiActionType.caregiverHub:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CaregiverHubScreen()),
        );
      case AiActionType.travel:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TravelHubScreen()),
        );
      case AiActionType.education:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const EducationHubScreen()),
        );
      case AiActionType.benefits:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const BenefitsHubScreen()),
        );
      case AiActionType.appointments:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AppointmentsScreen()),
        );
      case AiActionType.emergency:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const EmergencyScreen()),
        );
      case AiActionType.transport:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TransportHubScreen()),
        );
      case AiActionType.stepFreeRoute:
        final lat = double.tryParse(action.payload['lat'] ?? '') ?? 0;
        final lng = double.tryParse(action.payload['lng'] ?? '') ?? 0;
        final dest = TransportOption(
          id: action.payload['id'] ?? 'ai-dest',
          kind: action.payload['kind'] ?? 'transit',
          name: action.payload['name'] ?? 'Destination',
          lat: lat,
          lng: lng,
          summary: action.payload['summary'] ?? 'From AI Assistant',
          features: const ['stepFree'],
          stepFree: action.payload['stepFree'] != '0',
        );
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StepFreeRouteScreen(destination: dest),
          ),
        );
      case AiActionType.rights:
        final id = action.payload['topicId'] ?? '';
        RightsTopic topic = disabilityRightsTopics.first;
        for (final t in disabilityRightsTopics) {
          if (t.id == id) {
            topic = t;
            break;
          }
        }
        if (!mounted) return;
        await showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(topic.summary),
                const SizedBox(height: 12),
                for (final p in topic.points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $p'),
                  ),
              ],
            ),
          ),
        );
      default:
        break;
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _sending) return;

    final userMsg = ChatMessage(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.user,
      text: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _showDiscover = false;
      _sending = true;
      _messages.add(userMsg);
      _input.clear();
    });
    _scrollToEnd();

    try {
      final reply = await _ai.send(
        userMessage: text,
        history: _messages,
        profile: _profile,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            id: 'a-${DateTime.now().millisecondsSinceEpoch}',
            role: ChatRole.assistant,
            text: reply.text,
            createdAt: DateTime.now(),
            isError: reply.error != null && !reply.usedLiveModel,
            citations: reply.safety.citations,
            flags: reply.safety.flags,
            safetyScore: reply.safety.score,
            actions: reply.actions,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            id: 'e-${DateTime.now().millisecondsSinceEpoch}',
            role: ChatRole.assistant,
            text: 'Sorry — I hit a snag. Please try again.\n($e)',
            createdAt: DateTime.now(),
            isError: true,
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  Future<void> _newChat() async {
    await _ai.clearCurrentConversation();
    _ai.resetModel();
    if (!mounted) return;
    setState(() {
      _messages.clear();
      _showDiscover = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?.firstName ?? 'there';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => Navigator.of(context).maybePop(),
              onHistory: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _ai.lastBackendNote ??
                          'Conversation saves to your account automatically.',
                    ),
                  ),
                );
              },
              onMore: _newChat,
            ),
            if (_loadingProfile)
              const LinearProgressIndicator(minHeight: 2)
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _profile == null
                            ? 'Sign in for Passport-personalized answers'
                            : 'Using your Accessibility Passport · ${_profile!.passportId}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  _HeroCard(
                    userName: name,
                    controller: _input,
                    focusNode: _focus,
                    sending: _sending,
                    listening: _listening,
                    onSend: () => _send(_input.text),
                    onMic: _dictate,
                  ),
                  if (_showDiscover && _messages.isEmpty) ...[
                    const SizedBox(height: 18),
                    _TryAskingSection(prompts: _prompts, onTap: _send),
                    const SizedBox(height: 16),
                    _WelcomeBubble(name: name),
                    const SizedBox(height: 18),
                    _PopularSection(onTap: _send),
                    const SizedBox(height: 18),
                    _SmartToolsSection(onTap: _onTool),
                    const SizedBox(height: 14),
                    _ProfileSummaryCard(profile: _profile),
                  ],
                  if (_messages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    for (final m in _messages) ...[
                      _ChatBubble(
                        message: m,
                        onSpeak: m.isAssistant
                            ? () => _voice.speak(m.text)
                            : null,
                        onAction: m.isAssistant ? _runAction : null,
                        onFlag: m.isAssistant
                            ? () async {
                                await TrustService().queueOversight(
                                  prompt: 'user flag',
                                  reply: m.text,
                                  scan: SafetyScan(
                                    citations: m.citations,
                                    flags: [...m.flags, 'user-flag'],
                                    score: m.safetyScore,
                                  ),
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sent to human review'),
                                  ),
                                );
                              }
                            : null,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_sending) const _TypingBubble(),
                  ],
                ],
              ),
            ),
            if (!_showDiscover || _messages.isNotEmpty)
              _ComposerBar(
                controller: _input,
                sending: _sending,
                listening: _listening,
                onSend: () => _send(_input.text),
                onMic: _dictate,
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.onHistory,
    required this.onMore,
  });

  final VoidCallback onBack;
  final VoidCallback onHistory;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF1E1B4B),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'AI Accessibility Assistant',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E2A5E),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Your smart companion for an accessible life',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Chat history',
            onPressed: onHistory,
            icon: const Icon(Icons.history_rounded, color: AppColors.primary),
          ),
          IconButton(
            tooltip: 'New chat',
            onPressed: onMore,
            icon: const Icon(
              Icons.add_comment_outlined,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.userName,
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.listening,
    required this.onSend,
    required this.onMic,
  });

  final String userName;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final bool listening;
  final VoidCallback onSend;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF5B52E8), Color(0xFF4F46C8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello $userName! 👋',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "I'm here to help you find accessible solutions, plan your day, and answer any questions you have.",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Image.asset(
                'assets/images/ai_robot.png',
                height: 88,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !sending,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                ),
                IconButton(
                  tooltip: listening ? 'Stop listening' : 'Voice input',
                  onPressed: onMic,
                  icon: Icon(
                    listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: listening
                        ? const Color(0xFFE11D48)
                        : AppColors.primary,
                  ),
                ),
                Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: sending ? null : onSend,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: sending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TryAskingSection extends StatelessWidget {
  const _TryAskingSection({required this.prompts, required this.onTap});

  final List<(IconData, String, Color, Color)> prompts;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Try asking me',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1B4B),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: prompts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final p = prompts[i];
              return InkWell(
                onTap: () => onTap(p.$2),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: p.$4,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(p.$1, color: p.$3, size: 15),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          p.$2,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1B4B),
                            height: 1.25,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WelcomeBubble extends StatelessWidget {
  const _WelcomeBubble({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return _ChatBubble(
      message: ChatMessage(
        id: 'welcome',
        role: ChatRole.assistant,
        text:
            'Hi $name — I can help with navigation, healthcare, education, travel, government benefits and more. What would you like to do today?',
        createdAt: DateTime.now(),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    this.onSpeak,
    this.onFlag,
    this.onAction,
  });
  final ChatMessage message;
  final VoidCallback? onSpeak;
  final VoidCallback? onFlag;
  final ValueChanged<AiAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isUser ? null : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Row(
                children: [
                  const Icon(
                    Icons.smart_toy_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI Assistant',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1B4B),
                    ),
                  ),
                  const Spacer(),
                  if (onSpeak != null)
                    IconButton(
                      tooltip: 'Read aloud',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onSpeak,
                      icon: Icon(
                        Icons.volume_up_rounded,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Copy message',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message.text));
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Copied')));
                    },
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            if (!isUser) const SizedBox(height: 6),
            Text(
              message.text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.4,
                color: isUser ? Colors.white : const Color(0xFF374151),
              ),
            ),
            if (!isUser && message.actions.isNotEmpty && onAction != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final a in message.actions)
                    ActionChip(
                      label: Text(
                        a.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      backgroundColor: AppColors.primaryLight,
                      side: BorderSide.none,
                      onPressed: () => onAction!(a),
                    ),
                ],
              ),
            ],
            if (!isUser &&
                (message.citations.isNotEmpty || message.flags.isNotEmpty)) ...[
              const SizedBox(height: 8),
              if (message.citations.isNotEmpty)
                Text(
                  'Sources: ${message.citations.join(', ')}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (message.flags.isNotEmpty)
                Text(
                  'Safety ${message.safetyScore}: ${message.flags.join(' · ')}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.sos,
                  ),
                ),
            ],
            if (!isUser && onFlag != null)
              TextButton(
                onPressed: onFlag,
                child: const Text('Flag for human review'),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Thinking…',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularSection extends StatelessWidget {
  const _PopularSection({required this.onTap});
  final ValueChanged<String> onTap;

  static const _items = [
    (Icons.wc_rounded, 'Accessible washrooms nearby', Color(0xFF6C63FF)),
    (
      Icons.directions_walk_rounded,
      'Step-free route to metro station',
      Color(0xFF22C55E),
    ),
    (
      Icons.medical_services_outlined,
      'Telehealth: Talk to a doctor',
      Color(0xFF3B82F6),
    ),
    (
      Icons.apartment_rounded,
      'Best accessible hotels near me',
      Color(0xFFF97316),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Right Now',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.6,
          children: [
            for (final item in _items)
              InkWell(
                onTap: () {
                  if (item.$2.startsWith('Telehealth')) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TelehealthScreen(),
                      ),
                    );
                  } else {
                    onTap(item.$2);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF0F1F3)),
                  ),
                  child: Row(
                    children: [
                      Icon(item.$1, color: item.$3, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.$2,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1B4B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SmartToolsSection extends StatelessWidget {
  const _SmartToolsSection({required this.onTap});
  final ValueChanged<String> onTap;

  static const _tools = [
    'Place Summarizer',
    'Plain Language',
    'Translate',
    'Checklist Generator',
    'OCR / Read Sign',
    'AI Score Prediction',
    'Recommendations for You',
    'Accessible Route Plan',
    'Accessible Route Planner',
    'All AI Tools',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Tools',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in _tools)
              ActionChip(
                label: Text(t),
                onPressed: () => onTap(t),
                backgroundColor: AppColors.primaryLight,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                side: BorderSide.none,
              ),
          ],
        ),
      ],
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.profile});
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final profiles = profile?.accessibilityProfiles ?? const [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F1F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Accessibility Profile',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in (profiles.isEmpty ? ['Not set'] : profiles))
                Chip(
                  label: Text(p),
                  backgroundColor: AppColors.primaryLight,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              if (profile?.mobilityAid.isNotEmpty == true)
                Chip(
                  label: Text(profile!.mobilityAid),
                  backgroundColor: const Color(0xFFF3F4F6),
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.sending,
    required this.listening,
    required this.onSend,
    required this.onMic,
  });

  final TextEditingController controller;
  final bool sending;
  final bool listening;
  final VoidCallback onSend;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !sending,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: listening ? 'Listening…' : 'Ask a follow-up…',
                  filled: true,
                  fillColor: const Color(0xFFF8F9FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: listening ? 'Stop listening' : 'Voice input',
              onPressed: onMic,
              icon: Icon(
                listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: listening ? AppColors.sos : null,
              ),
            ),
            IconButton(
              tooltip: 'Send message',
              onPressed: sending ? null : onSend,
              icon: Icon(
                Icons.send_rounded,
                color: sending ? Colors.grey : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
