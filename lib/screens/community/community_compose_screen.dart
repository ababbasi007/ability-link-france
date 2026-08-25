import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/community.dart';
import '../../services/community_service.dart';
import '../../theme/app_colors.dart';

class CommunityComposeScreen extends StatefulWidget {
  const CommunityComposeScreen({
    super.key,
    this.initialType = 'post',
    this.groupId = '',
    this.city = '',
  });

  final String initialType;
  final String groupId;
  final String city;

  @override
  State<CommunityComposeScreen> createState() => _CommunityComposeScreenState();
}

class _CommunityComposeScreenState extends State<CommunityComposeScreen> {
  final _community = CommunityService();
  final _title = TextEditingController();
  final _body = TextEditingController();
  late final TextEditingController _city;
  final _opt1 = TextEditingController();
  final _opt2 = TextEditingController();
  final _opt3 = TextEditingController();
  late String _type;
  String _topic = 'Local life';
  bool _busy = false;

  static const _types = [
    ('discussion', 'Discussion'),
    ('question', 'Q&A'),
    ('experience', 'Experience'),
    ('post', 'Post'),
    ('tip', 'Tip'),
    ('issue', 'Issue'),
    ('poll', 'Poll'),
  ];

  @override
  void initState() {
    super.initState();
    _type =
        widget.initialType == 'local' ||
            widget.initialType == 'following' ||
            widget.initialType == 'groups' ||
            widget.initialType == 'events'
        ? 'post'
        : widget.initialType;
    if (_type == 'All') _type = 'post';
    _city = TextEditingController(text: widget.city);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _city.dispose();
    _opt1.dispose();
    _opt2.dispose();
    _opt3.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add a title and details')));
      return;
    }
    if (_type == 'poll') {
      final opts = [
        _opt1.text,
        _opt2.text,
        _opt3.text,
      ].map((e) => e.trim()).where((e) => e.isNotEmpty).length;
      if (opts < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Polls need at least two options')),
        );
        return;
      }
    }
    setState(() => _busy = true);
    try {
      await _community.createPost(
        type: _type,
        title: _title.text,
        body: _body.text,
        city: _city.text,
        topic: _topic,
        groupId: widget.groupId,
        pollOptions: _type == 'poll'
            ? [_opt1.text, _opt2.text, _opt3.text]
            : const [],
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.groupId.isEmpty ? 'New post' : 'Post in group',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: const Text('Publish'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _types)
                ChoiceChip(
                  label: Text(t.$2),
                  selected: _type == t.$1,
                  onSelected: (_) => setState(() => _type = t.$1),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: communityTopics.contains(_topic) ? _topic : 'Local life',
            decoration: const InputDecoration(
              labelText: 'Topic',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final t in communityTopics)
                DropdownMenuItem(value: t, child: Text(t)),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _topic = v);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _body,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Details',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _city,
            decoration: const InputDecoration(
              labelText: 'City (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_type == 'poll') ...[
            const SizedBox(height: 12),
            Text(
              'Poll options',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _opt1,
              decoration: const InputDecoration(
                labelText: 'Option 1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _opt2,
              decoration: const InputDecoration(
                labelText: 'Option 2',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _opt3,
              decoration: const InputDecoration(
                labelText: 'Option 3 (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
