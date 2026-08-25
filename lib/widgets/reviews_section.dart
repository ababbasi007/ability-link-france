import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/accessibility_review.dart';
import '../services/background_task.dart';
import '../services/place_report_service.dart';
import '../services/reviews_service.dart';
import '../theme/app_colors.dart';
import 'decoded_network_image.dart';

const kReviewEvidenceOptions = [
  'Ramp',
  'Elevator',
  'Accessible toilet',
  'Parking',
  'Step-free entrance',
  'Braille / tactile',
  'Hearing loop',
  'Sign language',
  'Quiet / sensory',
  'Service animal',
  'Staff help',
  'Signage',
  'Audio',
  'Lighting',
  'Crowding',
];

class ReviewsSection extends StatefulWidget {
  const ReviewsSection({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.fallbackRating,
    required this.fallbackCount,
    this.listingVerified = false,
  });

  final String targetType;
  final String targetId;
  final String targetName;
  final double fallbackRating;
  final int fallbackCount;
  final bool listingVerified;

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  final _service = ReviewsService();

  @override
  void initState() {
    super.initState();
    runInBackground(_service.ensureSeeded(), 'seed reviews');
  }

  Future<void> _write() async {
    final saved = await WriteReviewSheet.show(
      context,
      targetType: widget.targetType,
      targetId: widget.targetId,
      targetName: widget.targetName,
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks — your review helps others plan.'),
        ),
      );
    }
  }

  Future<void> _flag(AccessibilityReview review) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report this review?'),
        content: const Text(
          'Use this if the review looks fake, abusive, or not about accessibility.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Report'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.flag(review.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reported. Hidden after 3 reports.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _helpful(AccessibilityReview review) async {
    try {
      await _service.helpful(review.id);
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AccessibilityReview>>(
      stream: _service.watchFor(
        targetType: widget.targetType,
        targetId: widget.targetId,
      ),
      builder: (context, snap) {
        final all = snap.data ?? const <AccessibilityReview>[];
        final visible = all.where((r) => r.isVisible).toList();
        final stats = ReviewsService.statsFor(
          all,
          listingVerified: widget.listingVerified,
        );
        final rating = stats.count > 0 ? stats.average : widget.fallbackRating;
        final count = stats.count > 0 ? stats.count : widget.fallbackCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Accessibility reviews',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _write,
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: const Text('Write'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _ConfidenceBanner(
              stats: stats,
              listingVerified: widget.listingVerified,
              rating: rating,
              count: count,
            ),
            const SizedBox(height: 12),
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (visible.isEmpty)
              Text(
                'Be the first to share how accessible this is.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              )
            else
              for (final review in visible) ...[
                _ReviewCard(
                  review: review,
                  onFlag: () => _flag(review),
                  onHelpful: () => _helpful(review),
                ),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }
}

class _ConfidenceBanner extends StatelessWidget {
  const _ConfidenceBanner({
    required this.stats,
    required this.listingVerified,
    required this.rating,
    required this.count,
  });

  final ReviewStats stats;
  final bool listingVerified;
  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    final tone = stats.confidence >= 75
        ? const Color(0xFF22C55E)
        : stats.confidence >= 45
        ? const Color(0xFFF59E0B)
        : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, size: 18, color: tone),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  stats.confidenceLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: tone,
                  ),
                ),
              ),
              Text(
                '★ ${rating.toStringAsFixed(1)} · $count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stats.confidence / 100,
              minHeight: 6,
              color: tone,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              'Confidence ${stats.confidence}/100',
              stats.freshnessLabel,
              if (listingVerified) 'Listing verified',
              if (stats.withEvidence > 0) '${stats.withEvidence} with evidence',
            ].join(' · '),
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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.onFlag,
    required this.onHelpful,
  });

  final AccessibilityReview review;
  final VoidCallback onFlag;
  final VoidCallback onHelpful;

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
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  review.authorName.isEmpty
                      ? '?'
                      : review.authorName[0].toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _dateLabel(review.createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '★ ${review.overall}',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              IconButton(
                tooltip: 'Helpful',
                onPressed: onHelpful,
                icon: Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                visualDensity: VisualDensity.compact,
              ),
              Text(
                '${review.helpfulCount}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
              IconButton(
                tooltip: 'Report',
                onPressed: onFlag,
                icon: const Icon(Icons.flag_outlined, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.4,
                color: const Color(0xFF374151),
              ),
            ),
          ],
          if (review.ownerReply.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Provider reply',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
              ),
              child: Text(
                review.ownerReply,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.4,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
            ),
          ],
          if (review.hasEvidence) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (review.visitedInPerson)
                  const _Tag(label: 'Visited', color: AppColors.success),
                for (final e in review.evidence) _Tag(label: e),
              ],
            ),
          ],
          if (review.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photoUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: DecodedNetworkImage(
                    review.photoUrls[i],
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
          if (review.videoUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final url in review.videoUrls)
              TextButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(url);
                  if (uri == null) return;
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.videocam_outlined, size: 18),
                label: const Text('Watch video evidence'),
              ),
          ],
          _NeedScores(review: review),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime d) {
    final days = DateTime.now().difference(d).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 30) return '$days days ago';
    return '${d.month}/${d.day}/${d.year}';
  }
}

class _NeedScores extends StatelessWidget {
  const _NeedScores({required this.review});

  final AccessibilityReview review;

  @override
  Widget build(BuildContext context) {
    final items = <(String, int?)>[
      ('Mobility', review.mobility),
      ('Vision', review.vision),
      ('Hearing', review.hearing),
      ('Cognitive', review.cognitive),
    ].where((e) => e.$2 != null).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        children: [
          for (final item in items)
            Text(
              '${item.$1} ${item.$2}/5',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.color = AppColors.primary});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class WriteReviewSheet extends StatefulWidget {
  const WriteReviewSheet({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.targetName,
  });

  final String targetType;
  final String targetId;
  final String targetName;

  static Future<bool?> show(
    BuildContext context, {
    required String targetType,
    required String targetId,
    required String targetName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WriteReviewSheet(
        targetType: targetType,
        targetId: targetId,
        targetName: targetName,
      ),
    );
  }

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  final _comment = TextEditingController();
  final _picker = ImagePicker();
  final _service = ReviewsService();
  int _overall = 0;
  int? _mobility;
  int? _vision;
  int? _hearing;
  int? _cognitive;
  final _evidence = <String>{};
  final _photos = <Uint8List>[];
  ReportVideoAttachment? _video;
  bool _visited = true;
  bool _submitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photos.length >= ReviewsService.maxPhotos) return;
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _photos.add(bytes));
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (_video != null) return;
    final picked = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 45),
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    final ext = picked.path.split('.').last.toLowerCase();
    setState(
      () => _video = ReportVideoAttachment(
        bytes: bytes,
        extension: ext == 'mov' ? 'mov' : 'mp4',
        fileName: picked.name,
      ),
    );
  }

  Future<void> _pickVideoFile() async {
    if (_video != null) return;
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp4', 'mov', 'm4v'],
    );
    if (picked.isEmpty || !mounted) return;
    final file = picked.first;
    final bytes = await file.xFile.readAsBytes();
    if (bytes.isEmpty) return;
    final ext = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'mp4';
    setState(
      () => _video = ReportVideoAttachment(
        bytes: bytes,
        extension: ext,
        fileName: file.name,
      ),
    );
  }

  Future<void> _chooseVideoSource() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Record video'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Pick video file'),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    switch (choice) {
      case 'camera':
        await _pickVideo(ImageSource.camera);
      case 'gallery':
        await _pickVideo(ImageSource.gallery);
      case 'file':
        await _pickVideoFile();
    }
  }

  Future<void> _choosePhotoSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _pickPhoto(source);
  }

  Future<void> _submit() async {
    if (_overall < 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tap a star rating first.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await _service.submit(
        targetType: widget.targetType,
        targetId: widget.targetId,
        targetName: widget.targetName,
        overall: _overall,
        comment: _comment.text,
        evidence: _evidence.toList(),
        mobility: _mobility,
        vision: _vision,
        hearing: _hearing,
        cognitive: _cognitive,
        visitedInPerson: _visited,
        photoBytes: List.unmodifiable(_photos),
        videoAttachments: _video == null ? const [] : [_video!],
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Write an accessibility review',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              widget.targetName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Overall',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: 'Rate $i star${i == 1 ? '' : 's'}',
                    onPressed: () => setState(() => _overall = i),
                    icon: Icon(
                      i <= _overall
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
              ],
            ),
            _NeedPicker(
              label: 'Mobility',
              value: _mobility,
              onChanged: (v) => setState(() => _mobility = v),
            ),
            _NeedPicker(
              label: 'Vision',
              value: _vision,
              onChanged: (v) => setState(() => _vision = v),
            ),
            _NeedPicker(
              label: 'Hearing',
              value: _hearing,
              onChanged: (v) => setState(() => _hearing = v),
            ),
            _NeedPicker(
              label: 'Cognitive',
              value: _cognitive,
              onChanged: (v) => setState(() => _cognitive = v),
            ),
            const SizedBox(height: 8),
            Text(
              'Evidence (optional)',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in kReviewEvidenceOptions)
                  FilterChip(
                    label: Text(option),
                    selected: _evidence.contains(option),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _evidence.add(option);
                        } else {
                          _evidence.remove(option);
                        }
                      });
                    },
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'I experienced this in person / live',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              value: _visited,
              onChanged: (v) => setState(() => _visited = v),
            ),
            const SizedBox(height: 8),
            Text(
              'Photos & video (optional)',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _photos.length; i++)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _photos[i],
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: IconButton(
                          tooltip: 'Remove photo',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          icon: const Icon(Icons.cancel, size: 20),
                          onPressed: () =>
                              setState(() => _photos.removeAt(i)),
                        ),
                      ),
                    ],
                  ),
                if (_photos.length < ReviewsService.maxPhotos)
                  OutlinedButton.icon(
                    onPressed: _choosePhotoSource,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: Text('Photo (${_photos.length}/${ReviewsService.maxPhotos})'),
                  ),
                if (_video == null)
                  OutlinedButton.icon(
                    onPressed: _chooseVideoSource,
                    icon: const Icon(Icons.videocam_outlined, size: 18),
                    label: const Text('Add video'),
                  )
                else
                  InputChip(
                    label: Text(
                      _video!.fileName.isEmpty ? 'Video attached' : _video!.fileName,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onDeleted: () => setState(() => _video = null),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comment,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'What should others know?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Publish review',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedPicker extends StatelessWidget {
  const _NeedPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 12),
            ),
          ),
          for (var i = 1; i <= 5; i++)
            InkWell(
              onTap: () => onChanged(value == i ? null : i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  (value ?? 0) >= i ? Icons.circle : Icons.circle_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
