import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/accessibility_audit.dart';
import '../../models/accessible_service.dart';
import '../../models/place.dart';
import '../../models/place_category.dart';
import '../../models/place_photo_section.dart';
import '../../models/place_video_section.dart';
import '../../data/indoor_venues.dart';
import '../../services/accessible_routing_prefs_store.dart';
import '../../services/accessible_routing_service.dart';
import '../../services/ai_tools_service.dart';
import '../../services/audit_place_promotion.dart';
import '../../services/audit_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/place_contact_actions.dart';
import '../../services/place_visit_stats_service.dart';
import '../../services/places_service.dart';
import '../../services/routing_service.dart';
import '../../theme/app_colors.dart';
import '../screens/audit/audit_wizard_screen.dart';
import '../screens/benefits/government_offices_screen.dart';
import '../screens/healthcare/healthcare_hub_screen.dart';
import '../screens/indoor/indoor_map_screen.dart';
import '../screens/profile/place_reports_screen.dart';
import '../screens/providers/providers_directory_screen.dart';
import '../widgets/place_barrier_report_sheet.dart';
import '../widgets/place_community_tips_section.dart';
import '../widgets/place_improvement_sheet.dart';
import 'decoded_network_image.dart';
import 'place_qna_section.dart';
import 'reviews_section.dart';

/// Shared place detail bottom sheet (map + search).
class PlaceDetailSheet extends StatefulWidget {
  const PlaceDetailSheet({
    super.key,
    required this.place,
    required this.isFavorite,
    required this.onFavorite,
    this.distanceLabel,
    this.onViewOnMap,
    this.onSummarize,
    this.onShowRoute,
    this.onAddToList,
  });

  final AccessiblePlace place;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final String? distanceLabel;
  final VoidCallback? onViewOnMap;
  final VoidCallback? onSummarize;
  final ValueChanged<WalkingRoute>? onShowRoute;
  final VoidCallback? onAddToList;

  static Future<void> show(
    BuildContext context, {
    required AccessiblePlace place,
    required bool isFavorite,
    required VoidCallback onFavorite,
    String? distanceLabel,
    VoidCallback? onViewOnMap,
    VoidCallback? onSummarize,
    ValueChanged<WalkingRoute>? onShowRoute,
    VoidCallback? onAddToList,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaceDetailSheet(
        place: place,
        isFavorite: isFavorite,
        onFavorite: onFavorite,
        distanceLabel: distanceLabel,
        onViewOnMap: onViewOnMap,
        onSummarize: onSummarize,
        onShowRoute: onShowRoute,
        onAddToList: onAddToList,
      ),
    );
  }

  @override
  State<PlaceDetailSheet> createState() => _PlaceDetailSheetState();
}

class _PlaceDetailSheetState extends State<PlaceDetailSheet> {
  AccessiblePlace get place => widget.place;
  bool get isFavorite => widget.isFavorite;
  VoidCallback get onFavorite => widget.onFavorite;
  String? get distanceLabel => widget.distanceLabel;
  VoidCallback? get onViewOnMap => widget.onViewOnMap;
  VoidCallback? get onSummarize => widget.onSummarize;
  ValueChanged<WalkingRoute>? get onShowRoute => widget.onShowRoute;
  VoidCallback? get onAddToList => widget.onAddToList;

  final _visitStats = PlaceVisitStatsService();
  late Future<String?> _busyHoursFuture;

  @override
  void initState() {
    super.initState();
    _busyHoursFuture = _loadBusyHours();
  }

  Future<String?> _loadBusyHours() async {
    final live = await _visitStats.peakHoursLabel(place.id);
    if (live != null && live.isNotEmpty) return live;
    final hint = place.peakHoursHint.trim();
    return hint.isEmpty ? null : hint;
  }

  Future<void> _openVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _directions(BuildContext context) async {
    final origin = await LocationService.instance.ensure(force: true);
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final prefs = await AccessibleRoutingPrefsStore.instance.load();
      final route = await AccessibleRoutingService().route(
        fromLat: origin.lat,
        fromLng: origin.lng,
        toLat: place.lat,
        toLng: place.lng,
        prefs: prefs,
      );
      if (!context.mounted) return;
      Navigator.pop(context);
      if (onShowRoute != null) {
        Navigator.pop(context);
        onShowRoute!(route);
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Walking directions'),
          content: Text(
            '${route.distanceLabel} · ${route.durationLabel}'
            '${route.isLive ? '' : ' (straight-line estimate)'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            if (onViewOnMap != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onViewOnMap!();
                },
                child: const Text('Open map'),
              ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _openLinkedModule(BuildContext context) {
    final module = place.placeCategory.module;
    final route = switch (module) {
      PlaceCategoryModule.healthcare => MaterialPageRoute<void>(
        builder: (_) => const HealthcareHubScreen(),
      ),
      PlaceCategoryModule.benefits => MaterialPageRoute<void>(
        builder: (_) => GovernmentOfficesScreen(initialQuery: place.name),
      ),
      PlaceCategoryModule.education => MaterialPageRoute<void>(
        builder: (_) => const ProvidersDirectoryScreen(),
      ),
      PlaceCategoryModule.native => null,
    };
    if (route == null) return;
    Navigator.of(context).push(route);
  }

  String _linkedModuleLabel(PlaceCategoryModule module) => switch (module) {
    PlaceCategoryModule.healthcare => 'Open Healthcare & Rehab',
    PlaceCategoryModule.benefits => 'View government offices',
    PlaceCategoryModule.education => 'Find education providers',
    PlaceCategoryModule.native => '',
  };

  Future<void> _predictScore(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final profile = await AuthService().getCurrentProfile();
      final result = await AiToolsService().predictAccessibilityScore(
        place,
        profile: profile,
      );
      if (!context.mounted) return;
      Navigator.pop(context);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(result.title),
          content: SingleChildScrollView(child: Text(result.text)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _uploadCertificate(BuildContext context) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
    );
    if (picked.isEmpty) return;
    final file = picked.first;
    final bytes = await file.xFile.readAsBytes();
    if (bytes.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the selected file.')),
      );
      return;
    }
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await PlacesService().uploadAccessibilityCertificate(
        placeId: place.id,
        bytes: bytes,
        fileName: file.name,
      );
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certificate uploaded · venue marked certified'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _report(BuildContext context) async {
    final submitted = await PlaceBarrierReportSheet.show(
      context,
      placeId: place.id,
      placeName: place.name,
    );
    if (!submitted || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Report submitted. Track resolution status in My place reports.',
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PlaceReportsScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _suggestImprovement(BuildContext context) async {
    final submitted = await PlaceImprovementSheet.show(
      context,
      placeId: place.id,
      placeName: place.name,
    );
    if (!submitted || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Improvement suggestion submitted. Track it in My place reports.',
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PlaceReportsScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  String _dateLabel(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    final photos = place.labeledPhotos;
    final open = place.isOpenNow();

    return Container(
      margin: const EdgeInsets.only(top: 80),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (photos.isNotEmpty) _PhotoGallery(photos: photos),
              if (place.hasVideos) ...[
                const SizedBox(height: 14),
                _VideoSection(
                  videos: place.videoSections,
                  onOpen: _openVideo,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      place.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Save place',
                    onPressed: onFavorite,
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border,
                      color: isFavorite
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  if (onAddToList != null)
                    IconButton(
                      tooltip: 'Add to list',
                      onPressed: onAddToList,
                      icon: const Icon(Icons.playlist_add_rounded),
                    ),
                ],
              ),
              Text(
                place.address,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              if (distanceLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  distanceLabel!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
              if (place.hasContactInfo) ...[
                const SizedBox(height: 12),
                if (place.phone.isNotEmpty)
                  _ContactRow(
                    Icons.phone_outlined,
                    place.phone,
                    onTap: () => PlaceContactActions.call(place.phone),
                  ),
                if (place.hours.isNotEmpty)
                  _ContactRow(Icons.schedule_outlined, place.hours),
                if (place.website.isNotEmpty)
                  _ContactRow(
                    Icons.language_outlined,
                    place.website,
                    onTap: () => PlaceContactActions.openWebsite(place.website),
                  ),
              ],
              FutureBuilder<String?>(
                future: _busyHoursFuture,
                builder: (context, snap) {
                  final label = snap.data;
                  if (label == null || label.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.insights_outlined,
                            size: 18,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (place.hasAuditDetails) ...[
                const SizedBox(height: 14),
                Text(
                  'Verified accessibility details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...AuditPlacePromotion.labeledDetails(place.auditDetails).map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            row.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Text(
                            row.value,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E1B4B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (place.lastAuditScore > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Audit score ${place.lastAuditScore}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    label: 'Score ${place.score}',
                    color: AppColors.primary,
                  ),
                  if (place.governmentCertified)
                    _InfoChip(
                      label: place.inspectionDate == null
                          ? 'Government certified'
                          : 'Government certified · ${_dateLabel(place.inspectionDate!)}',
                      color: const Color(0xFFFF3B30),
                    ),
                  if (place.features.contains(PlaceAmenities.dropOff))
                    _InfoChip(
                      label: place.dropOffDistance.isEmpty &&
                              place.dropOffLocation.isEmpty
                          ? 'Accessible drop-off'
                          : [
                              'Drop-off',
                              if (place.dropOffDistance.isNotEmpty)
                                place.dropOffDistance,
                              if (place.dropOffLocation.isNotEmpty)
                                place.dropOffLocation,
                            ].join(' · '),
                      color: const Color(0xFF0F766E),
                    ),
                  if (place.features.contains(PlaceAmenities.evAccessibleParking) ||
                      place.evAccessibleSpaces > 0)
                    _InfoChip(
                      label: place.evAccessibleSpaces > 0
                          ? 'EV accessible · ${place.evAccessibleSpaces} spaces'
                          : 'Accessible EV parking',
                      color: const Color(0xFF2563EB),
                    ),
                  if (place.features.contains(PlaceAmenities.evCharging))
                    const _InfoChip(
                      label: 'Accessible EV charging',
                      color: Color(0xFF7C3AED),
                    ),
                  _InfoChip(
                    label: '★ ${place.rating} (${place.reviewCount})',
                    color: const Color(0xFFF59E0B),
                  ),
                  _InfoChip(
                    label: open ? 'Open now' : 'Closed',
                    color: open
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                  ),
                  if (place.verified)
                    const _InfoChip(
                      label: 'Ability Link verified',
                      color: AppColors.primary,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (place.description.isNotEmpty)
                Text(
                  place.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.4,
                    color: const Color(0xFF374151),
                  ),
                ),
              const SizedBox(height: 14),
              if (place.resolvedServices.isNotEmpty) ...[
                Text(
                  'Accessible services',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  for (final service in place.resolvedServices)
                    _ServiceRow(service: service),
                ],
                const SizedBox(height: 14),
              ],
              Text(
                'Accessibility features',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in place.features)
                    Chip(
                      label: Text(PlaceAmenities.label(f)),
                      backgroundColor: AppColors.primaryLight,
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      side: BorderSide.none,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Supports',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final n in place.needs)
                    Chip(
                      label: Text(PlaceAmenities.label(n)),
                      backgroundColor: const Color(0xFFF3F4F6),
                      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                      side: BorderSide.none,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (place.placeCategory.module != PlaceCategoryModule.native) ...[
                OutlinedButton.icon(
                  onPressed: () => _openLinkedModule(context),
                  icon: Icon(place.placeCategory.icon),
                  label: Text(_linkedModuleLabel(place.placeCategory.module)),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _directions(context),
                      icon: const Icon(Icons.directions_walk_rounded),
                      label: const Text('Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _report(context),
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Report barrier'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _suggestImprovement(context),
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  label: const Text('Suggest accessibility improvement'),
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<AccessibilityAudit?>(
                stream: AuditService().watchLatestForPlace(place.id),
                builder: (context, snap) {
                  final audit = snap.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (audit != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Latest audit score ${audit.score} · ${audit.auditorName}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: () {
                          final nav = Navigator.of(context);
                          Navigator.pop(context);
                          nav.push(
                            MaterialPageRoute<void>(
                              builder: (_) => AuditWizardScreen(place: place),
                            ),
                          );
                        },
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Start accessibility audit'),
                      ),
                    ],
                  );
                },
              ),
              if (onViewOnMap != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onViewOnMap,
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('View on Ability Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
              if (onSummarize != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onSummarize,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('AI place summary'),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _predictScore(context),
                  icon: const Icon(Icons.insights_rounded),
                  label: Text(
                    place.score <= 0
                        ? 'Predict accessibility score'
                        : 'Re-check score with AI',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _uploadCertificate(context),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(
                    place.certificateUrl.isEmpty
                        ? 'Upload accessibility certificate'
                        : 'Replace certificate / inspection report',
                  ),
                ),
              ),
              if (place.certificateUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(place.certificateUrl);
                    if (uri == null) return;
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('View uploaded certificate'),
                ),
              ],
              if (indoorVenueForPlace(place.id) != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => IndoorMapScreen(placeId: place.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.layers_rounded),
                    label: const Text('Open indoor map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              PlaceCommunityTipsSection(
                placeId: place.id,
                placeName: place.name,
              ),
              const SizedBox(height: 20),
              ReviewsSection(
                targetType: 'place',
                targetId: place.id,
                targetName: place.name,
                fallbackRating: place.rating,
                fallbackCount: place.reviewCount,
                listingVerified: place.verified,
              ),
              const SizedBox(height: 20),
              PlaceQnaSection(
                targetType: 'place',
                targetId: place.id,
                targetName: place.name,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoGallery extends StatefulWidget {
  const _PhotoGallery({required this.photos});

  final List<PlacePhotoSection> photos;

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 180,
            child: PageView.builder(
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final photo = widget.photos[i];
                return DecodedNetworkImage(
                  photo.url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.primaryLight,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                widget.photos[_page].label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
              ),
            ),
            if (widget.photos[_page].source == 'audit')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Audit photo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        if (widget.photos.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.photos.length; i++)
                Container(
                  width: i == _page ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _page
                        ? AppColors.primary
                        : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow(this.icon, this.value, {this.onTap});

  final IconData icon;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      value,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: onTap == null ? const Color(0xFF374151) : AppColors.primary,
        decoration: onTap == null ? null : TextDecoration.underline,
        decorationColor: AppColors.primary.withValues(alpha: 0.4),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: text),
              if (onTap != null)
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _VideoSection extends StatelessWidget {
  const _VideoSection({required this.videos, required this.onOpen});

  final List<PlaceVideoSection> videos;
  final Future<void> Function(String url) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Walkthrough & navigation videos',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final video in videos)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onOpen(video.url),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          video.isNavigation
                              ? Icons.navigation_rounded
                              : Icons.play_circle_outline_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              video.isNavigation
                                  ? 'Navigation video'
                                  : 'Walkthrough video',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.open_in_new_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});

  final AccessibleServiceItem service;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (service.description.isNotEmpty)
                  Text(
                    service.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 1.35,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
              ],
            ),
          ),
          if (service.source == 'audit')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Verified',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
