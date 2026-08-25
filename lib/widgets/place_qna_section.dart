import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/place_qna.dart';
import '../services/place_qna_service.dart';
import '../theme/app_colors.dart';

class PlaceQnaSection extends StatefulWidget {
  const PlaceQnaSection({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.targetName,
  });

  final String targetType;
  final String targetId;
  final String targetName;

  @override
  State<PlaceQnaSection> createState() => _PlaceQnaSectionState();
}

class _PlaceQnaSectionState extends State<PlaceQnaSection> {
  final _service = PlaceQnaService();

  Future<void> _askQuestion() async {
    final ctrl = TextEditingController();
    final question = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ask a question'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g. Is there step-free access to the upper floor?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (question == null || question.trim().isEmpty) return;
    try {
      await _service.ask(
        targetType: widget.targetType,
        targetId: widget.targetId,
        targetName: widget.targetName,
        question: question,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question submitted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PlaceQnaQuestion>>(
      stream: _service.watchFor(
        targetType: widget.targetType,
        targetId: widget.targetId,
      ),
      builder: (context, snap) {
        final questions = snap.hasError
            ? const <PlaceQnaQuestion>[]
            : snap.data ?? const <PlaceQnaQuestion>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Questions & answers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _askQuestion,
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text('Ask'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (questions.isEmpty)
              Text(
                'No questions yet — be the first to ask!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              )
            else
              for (final q in questions) ...[
                _QnaCard(q: q, service: _service),
                const SizedBox(height: 8),
              ],
          ],
        );
      },
    );
  }
}

class _QnaCard extends StatefulWidget {
  const _QnaCard({required this.q, required this.service});

  final PlaceQnaQuestion q;
  final PlaceQnaService service;

  @override
  State<_QnaCard> createState() => _QnaCardState();
}

class _QnaCardState extends State<_QnaCard> {
  bool _showAnswerField = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    try {
      await widget.service.answer(
        questionId: widget.q.id,
        body: _ctrl.text,
      );
      if (mounted) {
        setState(() => _showAnswerField = false);
        _ctrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Answer posted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.q;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.help_outline,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    q.question,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(
                q.authorName.isNotEmpty ? q.authorName : 'Community member',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (q.isAnswered) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        q.answerBody,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _showAnswerField = !_showAnswerField),
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Answer'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
              if (_showAnswerField) ...[
                TextField(
                  controller: _ctrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Your answer…',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _submitAnswer,
                    child: const Text('Post answer'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
