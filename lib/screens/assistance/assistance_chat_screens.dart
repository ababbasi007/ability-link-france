import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/assistance.dart';
import '../../models/service_provider.dart';
import '../../services/assistance_service.dart';
import '../../theme/app_colors.dart';
import '../providers/provider_profile_screen.dart';

class AssistanceInboxScreen extends StatelessWidget {
  const AssistanceInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final assist = AssistanceService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Assistant messages',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: assist.watchThreads(),
        builder: (context, snap) {
          final threads = snap.data ?? const [];
          if (threads.isEmpty) {
            return Center(
              child: Text(
                'Message an assistant from the marketplace to start a thread.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: threads.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = threads[i];
              final id = (t['id'] as String?) ?? '';
              final name = (t['providerName'] as String?) ?? 'Assistant';
              final last = (t['lastMessage'] as String?) ?? '';
              final photo = (t['photoUrl'] as String?) ?? '';
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: CircleAvatar(
                  backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
                  child: photo.isEmpty
                      ? Text(name.isEmpty ? '?' : name[0])
                      : null,
                ),
                title: Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AssistanceChatScreen(
                        provider: ServiceProvider(
                          id: id,
                          name: name,
                          title: '',
                          category: 'assistance',
                          specialty: '',
                          bio: '',
                          rating: 0,
                          reviewCount: 0,
                          priceFrom: 0,
                          currency: '\$',
                          languages: const [],
                          services: const [],
                          accessibilityTags: const [],
                          city: '',
                          photoUrl: photo,
                          assistanceType:
                              (t['assistanceType'] as String?) ?? '',
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class AssistanceChatScreen extends StatefulWidget {
  const AssistanceChatScreen({super.key, required this.provider});

  final ServiceProvider provider;

  @override
  State<AssistanceChatScreen> createState() => _AssistanceChatScreenState();
}

class _AssistanceChatScreenState extends State<AssistanceChatScreen> {
  final _assist = AssistanceService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _assist.ensureThread(provider: widget.provider);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    await _assist.sendMessage(providerId: widget.provider.id, body: text);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          p.name,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'View provider profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProviderProfileScreen(
                    providerId: p.id,
                    provider: p.id.isEmpty ? null : p,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<AssistantMessage>>(
              stream: _assist.watchMessages(p.id),
              builder: (context, snap) {
                final messages = snap.data ?? const <AssistantMessage>[];
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final mine = m.uid.isNotEmpty && m.uid == _uid;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                        ),
                        decoration: BoxDecoration(
                          color: mine ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          m.body,
                          style: GoogleFonts.plusJakartaSans(
                            color: mine
                                ? Colors.white
                                : const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Message ${p.name}…',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
