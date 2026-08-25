import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/place_barrier_report.dart';
import '../services/place_report_service.dart';
import '../theme/app_colors.dart';

/// Structured barrier report with category picker, notes, and photo evidence.
class PlaceBarrierReportSheet extends StatefulWidget {
  const PlaceBarrierReportSheet({
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
      builder: (_) => PlaceBarrierReportSheet(
        placeId: placeId,
        placeName: placeName,
      ),
    );
    return submitted == true;
  }

  @override
  State<PlaceBarrierReportSheet> createState() =>
      _PlaceBarrierReportSheetState();
}

class _PlaceBarrierReportSheetState extends State<PlaceBarrierReportSheet> {
  final _details = TextEditingController();
  final _picker = ImagePicker();
  final _photos = <Uint8List>[];
  ReportVideoAttachment? _video;
  String? _category;
  bool _submitting = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  PlaceBarrierCategory? get _selected =>
      _category == null ? null : PlaceBarrierCategory.byId(_category!);

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

  Future<void> _submit() async {
    final cat = _category;
    if (cat == null) {
      _toast('Choose what you are reporting');
      return;
    }
    setState(() => _submitting = true);
    try {
      await PlaceReportService().submit(
        placeId: widget.placeId,
        placeName: widget.placeName,
        category: cat,
        details: _details.text,
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
    final selected = _selected;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 12),
              Text(
                'Report a barrier',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
              Text(
                widget.placeName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'What is the issue?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cat in PlaceBarrierCategory.barrierReportCategories)
                    FilterChip(
                      label: Text(
                        cat.label,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11),
                      ),
                      avatar: Icon(cat.icon, size: 16, color: AppColors.primary),
                      selected: _category == cat.id,
                      onSelected: (_) => setState(() => _category = cat.id),
                      selectedColor: AppColors.primaryLight,
                      checkmarkColor: AppColors.primary,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _details,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: selected?.hint ??
                      'Describe the barrier or incorrect information…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'Photo evidence',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_photos.length}/${PlaceReportService.maxPhotos}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < _photos.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
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
                          child: Material(
                            color: const Color(0xFFEF4444),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => setState(() => _photos.removeAt(i)),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_photos.length < PlaceReportService.maxPhotos) ...[
                    if (_photos.isNotEmpty) const SizedBox(width: 8),
                    InkWell(
                      onTap: _submitting ? null : _choosePhotoSource,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                          color: const Color(0xFFF9FAFB),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'Video evidence',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _video == null
                        ? '0/${PlaceReportService.maxVideos}'
                        : '1/${PlaceReportService.maxVideos}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_video == null)
                InkWell(
                  onTap: _submitting ? null : _chooseVideoSource,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                      color: const Color(0xFFF9FAFB),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.videocam_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add video (mp4/mov, up to 45 s)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    color: const Color(0xFFF9FAFB),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.movie_creation_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _video!.fileName.isNotEmpty
                              ? _video!.fileName
                              : 'Video attached',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _video = null),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        tooltip: 'Remove video',
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Submit report',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
