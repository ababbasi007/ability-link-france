import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/community.dart';
import '../services/background_task.dart';
import '../services/community_service.dart';
import '../theme/app_colors.dart';

class PlaceCommunityTipsSection extends StatefulWidget {
  const PlaceCommunityTipsSection({
    super.key,
    required this.placeId,
    required this.placeName,
    this.city = '',
  });

  final String placeId;
  final String placeName;
  final String city;

  @override
  State<PlaceCommunityTipsSection> createState() =>
      _PlaceCommunityTipsSectionState();
}

class _PlaceCommunityTipsSectionState extends State<PlaceCommunityTipsSection> {
  final _service = CommunityService();

  @override
  void initState() {
    super.initState();
    runInBackground(_service.ensureSeeded(), 'seed community tips');
  }

  Future<void> _shareTip() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share an accessibility tip'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Short title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'What helped you here?',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Post tip'),
          ),
        ],
      ),
    );
    final title = titleCtrl.text.trim();
    final body = bodyCtrl.text.trim();
    titleCtrl.dispose();
    bodyCtrl.dispose();
    if (saved != true || title.isEmpty || body.isEmpty) return;
    try {
      await _service.createTipForPlace(
        placeId: widget.placeId,
        placeName: widget.placeName,
        title: title,
        body: body,
        city: widget.city,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tip posted for this place.')),
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
    return StreamBuilder<List<CommunityPost>>(
      stream: _service.watchTipsForPlace(widget.placeId),
      builder: (context, snap) {
        final tips = snap.data ?? const <CommunityPost>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Community tips',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _shareTip,
                  icon: const Icon(Icons.tips_and_updates_outlined, size: 18),
                  label: const Text('Share tip'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Crowdsourced advice from people who have visited this place.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (tips.isEmpty)
              Text(
                'No tips yet — share what helped you navigate here.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              )
            else
              for (final tip in tips) ...[
                _TipCard(tip: tip),
                const SizedBox(height: 8),
              ],
          ],
        );
      },
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final CommunityPost tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tip.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (tip.likeCount > 0)
                Text(
                  '${tip.likeCount} helpful',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tip.body,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.4,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tip.authorName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
