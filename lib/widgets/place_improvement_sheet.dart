import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/place_barrier_report.dart';
import '../services/place_report_service.dart';
import '../theme/app_colors.dart';

const kImprovementAreas = [
  'Entry / ramp',
  'Restroom',
  'Parking',
  'Signage / wayfinding',
  'Seating / rest areas',
  'Elevator / lift',
  'Other',
];

/// Dedicated flow for suggesting accessibility features and entry improvements.
class PlaceImprovementSheet extends StatefulWidget {
  const PlaceImprovementSheet({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  final String placeId;
  final String placeName;

  static Future<bool> show(
    BuildContext context, {
    required String placeId,
    required String placeName,
  }) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaceImprovementSheet(
        placeId: placeId,
        placeName: placeName,
      ),
    );
    return submitted == true;
  }

  @override
  State<PlaceImprovementSheet> createState() => _PlaceImprovementSheetState();
}

class _PlaceImprovementSheetState extends State<PlaceImprovementSheet> {
  final _details = TextEditingController();
  final _picker = ImagePicker();
  final _areas = <String>{};
  final _photos = <Uint8List>[];
  ReportVideoAttachment? _video;
  bool _submitting = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photos.length >= PlaceReportService.maxPhotos) return;
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

  String _composeDetails() {
    final parts = <String>[];
    if (_areas.isNotEmpty) {
      parts.add('Areas: ${_areas.join(', ')}');
    }
    final text = _details.text.trim();
    if (text.isNotEmpty) parts.add(text);
    return parts.join('\n\n');
  }

  Future<void> _submit() async {
    if (_areas.isEmpty) {
      _toast('Pick at least one area to improve');
      return;
    }
    final composed = _composeDetails();
    if (composed.isEmpty &&
        _photos.isEmpty &&
        _video == null) {
      _toast('Describe the improvement or add a photo/video');
      return;
    }
    setState(() => _submitting = true);
    try {
      await PlaceReportService().submit(
        placeId: widget.placeId,
        placeName: widget.placeName,
        category: PlaceBarrierCategory.featureImprovement.id,
        details: composed,
        photoBytes: List.unmodifiable(_photos),
        videoAttachments: _video == null ? const [] : [_video!],
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _toast('$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              'Suggest an improvement',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              widget.placeName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              PlaceBarrierCategory.featureImprovement.hint,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'What should improve?',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final area in kImprovementAreas)
                  FilterChip(
                    label: Text(area),
                    selected: _areas.contains(area),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _areas.add(area);
                        } else {
                          _areas.remove(area);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _details,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Describe the change',
                hintText:
                    'e.g. Add a permanent ramp at the side entrance, widen Door B…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Photos & video (optional)',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
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
                if (_photos.length < PlaceReportService.maxPhotos)
                  OutlinedButton.icon(
                    onPressed: _choosePhotoSource,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: Text(
                      'Photo (${_photos.length}/${PlaceReportService.maxPhotos})',
                    ),
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
                      _video!.fileName.isEmpty
                          ? 'Video attached'
                          : _video!.fileName,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onDeleted: () => setState(() => _video = null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
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
                        'Submit suggestion',
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
