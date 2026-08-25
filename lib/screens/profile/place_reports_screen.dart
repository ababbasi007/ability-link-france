import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/place_report.dart';
import '../../services/place_report_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/decoded_network_image.dart';
import '../map/accessibility_map_screen.dart';

class PlaceReportsScreen extends StatefulWidget {
  const PlaceReportsScreen({super.key});

  @override
  State<PlaceReportsScreen> createState() => _PlaceReportsScreenState();
}

class _PlaceReportsScreenState extends State<PlaceReportsScreen> {
  final _reports = PlaceReportService();
  String _filter = 'all';

  bool _matches(PlaceReport report) => switch (_filter) {
    'open' => report.isOpen || report.status == PlaceReportStatus.inReview,
    'resolved' => report.isResolved,
    _ => true,
  };

  void _openPlace(PlaceReport report) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccessibilityMapScreen(
          showBack: true,
          initialPlaceId: report.placeId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My place reports',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<PlaceReport>>(
        stream: _reports.watchMine(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data ?? const <PlaceReport>[];
          final list = all.where(_matches).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Track barrier reports and listing corrections you submitted on the map.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final f in const [
                      ('all', 'All'),
                      ('open', 'Open'),
                      ('resolved', 'Resolved'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f.$2),
                          selected: _filter == f.$1,
                          onSelected: (_) => setState(() => _filter = f.$1),
                          selectedColor: AppColors.primaryLight,
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _filter == f.$1
                                ? AppColors.primary
                                : const Color(0xFF1E1B4B),
                          ),
                          side: BorderSide(
                            color: _filter == f.$1
                                ? AppColors.primary
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: all.isEmpty
                    ? _EmptyState(onMap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const AccessibilityMapScreen(showBack: true),
                          ),
                        );
                      })
                    : list.isEmpty
                    ? Center(
                        child: Text(
                          'No ${_filter == 'open' ? 'open' : 'resolved'} reports.',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _ReportCard(
                          report: list[i],
                          onOpenPlace: () => _openPlace(list[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onOpenPlace});

  final PlaceReport report;
  final VoidCallback onOpenPlace;

  String get _when {
    final at = report.createdAt;
    if (at == null) return 'Submitted recently';
    final local = at.toLocal();
    final y = local.year;
    final mo = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d · $h:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = PlaceReportStatus.color(report.status);
    final category = report.categoryMeta;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _ReportDetailSheet.show(context, report, onOpenPlace),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF0F1F3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PlaceReportStatus.icon(report.status),
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          PlaceReportStatus.label(report.status),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (report.photoUrls.isNotEmpty || report.videoUrls.isNotEmpty)
                    Icon(
                      report.videoUrls.isNotEmpty
                          ? Icons.videocam_outlined
                          : Icons.photo_camera_outlined,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                report.placeName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (category != null) ...[
                    Icon(category.icon, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      report.categoryLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (report.details.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  report.details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 1.35,
                    color: const Color(0xFF374151),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _when,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportDetailSheet extends StatelessWidget {
  const _ReportDetailSheet({required this.report, required this.onOpenPlace});

  final PlaceReport report;
  final VoidCallback onOpenPlace;

  static Future<void> show(
    BuildContext context,
    PlaceReport report,
    VoidCallback onOpenPlace,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _ReportDetailSheet(report: report, onOpenPlace: onOpenPlace),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = PlaceReportStatus.color(report.status);
    final category = report.categoryMeta;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    PlaceReportStatus.label(report.status),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.placeName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 6),
            if (category != null)
              Text(
                category.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                PlaceReportStatus.message(report.status),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.4,
                  color: const Color(0xFF374151),
                ),
              ),
            ),
            if (report.details.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Your note',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                report.details,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.4,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
            if (report.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.photoUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: DecodedNetworkImage(
                      report.photoUrls[i],
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
            if (report.videoUrls.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Video evidence',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final url in report.videoUrls)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(url);
                      if (uri == null) return;
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: Text(
                      'Open video evidence',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                onOpenPlace();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'View on map',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onMap});

  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'No reports yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Report a broken elevator, blocked ramp, or incorrect listing from any place on the map.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onMap,
              child: const Text('Open accessibility map'),
            ),
          ],
        ),
      ),
    );
  }
}
