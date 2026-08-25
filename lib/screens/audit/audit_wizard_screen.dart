import '../../services/background_task.dart';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/accessibility_audit.dart';
import '../../models/place.dart';
import '../../services/audit_service.dart';
import '../../services/location_service.dart';
import '../../services/places_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/decoded_network_image.dart';

class AuditWizardScreen extends StatefulWidget {
  const AuditWizardScreen({super.key, this.existing, this.place});

  final AccessibilityAudit? existing;
  final AccessiblePlace? place;

  @override
  State<AuditWizardScreen> createState() => _AuditWizardScreenState();
}

class _AuditWizardScreenState extends State<AuditWizardScreen> {
  final _audits = AuditService();
  final _places = PlacesService();
  final _picker = ImagePicker();

  late AccessibilityAudit _draft;
  int _step = 0;
  bool _saving = false;
  bool _readOnly = false;

  static const _purple = Color(0xFF5B4BDB);

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _draft = widget.existing!;
    } else if (_audits.uid != null) {
      _draft = _audits.newDraft(place: widget.place);
    } else {
      _draft = AccessibilityAudit(
        id: '',
        uid: '',
        auditorName: 'Guest',
        placeId: widget.place?.id ?? '',
        placeName: widget.place?.name ?? '',
        placeAddress: widget.place?.address ?? '',
        category: _categoryFromPlace(widget.place),
      );
    }
    if (_draft.category.isNotEmpty &&
        !AuditCatalog.categories.contains(_draft.category)) {
      _draft = _draft.copyWith(category: _categoryFromPlace(widget.place));
    }
    final existingUid = widget.existing?.uid;
    _readOnly =
        existingUid != null &&
        existingUid.isNotEmpty &&
        existingUid != _audits.uid;
    runInBackground(_places.ensureSeeded(), 'seed places');
  }

  String _categoryFromPlace(AccessiblePlace? place) {
    return switch (place?.category) {
      'cafe' => 'Restaurant / Cafe',
      'hospital' => 'Hospital',
      'library' => 'Library',
      'mall' => 'Shopping',
      'transit' => 'Transit',
      'park' => 'Park',
      _ =>
        place == null || place.category.isEmpty ? 'Restaurant / Cafe' : 'Other',
    };
  }

  ({int score, Map<String, int> sections}) get _computed =>
      AccessibilityAudit.compute(_draft.answers);

  Future<void> _persist({bool submitting = false}) async {
    setState(() => _saving = true);
    try {
      if (submitting) {
        await _audits.submit(_draft);
      } else {
        final id = await _audits.saveDraft(_draft);
        if (_draft.id.isEmpty) {
          _draft = _draft.copyWith(id: id);
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveDraftTap() async {
    try {
      await _persist();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _next() async {
    try {
      if (_step == 0 && _draft.placeName.trim().isEmpty) {
        throw StateError('Enter a place name to continue');
      }
      if (!_readOnly) await _persist();
      if (!mounted) return;
      if (_step < 9) setState(() => _step++);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.maybePop(context);
      return;
    }
    setState(() => _step--);
  }

  Future<void> _submit() async {
    try {
      if (!_draft.confirmed) {
        throw StateError('Please confirm the information is accurate');
      }
      await _persist(submitting: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audit submitted · ${_computed.score}%')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _setAnswer(String sectionId, String itemId, String value) {
    if (_readOnly) return;
    final next = Map<String, String>.from(_draft.answers);
    next['$sectionId.$itemId'] = value;
    setState(() => _draft = _draft.copyWith(answers: next));
  }

  void _setField(String key, String value) {
    if (_readOnly) return;
    final next = Map<String, String>.from(_draft.measurements);
    next[key] = value;
    setState(() => _draft = _draft.copyWith(measurements: next));
  }

  String _field(String key) => _draft.measurements[key] ?? '';

  Future<void> _addPhoto({String caption = ''}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() {
      _draft = _draft.copyWith(
        photos: [
          ..._draft.photos,
          AuditPhoto(uri: file.path, caption: caption),
        ],
      );
    });
  }

  Future<void> _useGps() async {
    final loc = await LocationService.instance.ensure(force: true);
    if (!mounted) return;
    setState(() {
      _draft = _draft.copyWith(
        gps: '${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)}',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final last = _step == 9;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'Audit a Place',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (!_readOnly)
            TextButton(
              onPressed: last ? () => setState(() => _step = 0) : _saveDraftTap,
              child: Text(
                last ? 'Edit' : 'Save Draft',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: _purple,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _StepStrip(current: _step, onTap: (i) => setState(() => _step = i)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              children: [_body()],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _saving
                      ? null
                      : (last
                            ? (_readOnly
                                  ? () => Navigator.maybePop(context)
                                  : _submit)
                            : _next),
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    last
                        ? (_readOnly ? 'Close' : 'Submit Audit')
                        : AuditCatalog.nextLabels[_step],
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    return switch (_step) {
      0 => _basics(),
      1 => _section(AuditCatalog.section('parking')),
      2 => _section(AuditCatalog.section('entrance')),
      3 => _section(AuditCatalog.section('mobility')),
      4 => _section(AuditCatalog.section('toilet')),
      5 => _section(AuditCatalog.section('visual')),
      6 => _section(AuditCatalog.section('hearing')),
      7 => _section(AuditCatalog.section('cognitive')),
      8 => _servicesEmergency(),
      _ => _review(),
    };
  }

  Widget _title(String text, {String? scoreId}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E1B4B),
              ),
            ),
          ),
          if (scoreId != null) _scorePill(scoreId),
        ],
      ),
    );
  }

  Widget _scorePill(String sectionId) {
    final n = AccessibilityAudit(
      id: _draft.id,
      uid: _draft.uid,
      auditorName: _draft.auditorName,
      placeId: _draft.placeId,
      placeName: _draft.placeName,
      placeAddress: _draft.placeAddress,
      category: _draft.category,
      answers: _draft.answers,
      sectionScores: _computed.sections,
    ).sectionOutOf10(sectionId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$n/10',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: const Color(0xFF16A34A),
        ),
      ),
    );
  }

  Widget _basics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Basic Information'),
        _coverPicker(),
        const SizedBox(height: 14),
        _input(
          'Place Name',
          _draft.placeName,
          (v) => _draft = _draft.copyWith(placeName: v),
        ),
        _dropdown(
          'Place Category',
          AuditCatalog.categories.contains(_draft.category)
              ? _draft.category
              : null,
          AuditCatalog.categories,
          (v) => setState(() => _draft = _draft.copyWith(category: v ?? '')),
        ),
        _input(
          'Address',
          _draft.placeAddress,
          (v) => _draft = _draft.copyWith(placeAddress: v),
          maxLines: 2,
        ),
        _input(
          'Location (GPS)',
          _draft.gps,
          (v) => _draft = _draft.copyWith(gps: v),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _useGps,
            icon: const Icon(Icons.my_location_rounded, size: 18),
            label: const Text('Use My Location'),
          ),
        ),
        _input(
          'Phone Number',
          _draft.phone,
          (v) => _draft = _draft.copyWith(phone: v),
        ),
        _input(
          'Website',
          _draft.website,
          (v) => _draft = _draft.copyWith(website: v),
        ),
      ],
    );
  }

  Widget _coverPicker() {
    AuditPhoto? cover;
    for (final p in _draft.photos) {
      if (p.caption == 'cover') {
        cover = p;
        break;
      }
    }
    cover ??= _draft.photos.isEmpty ? null : _draft.photos.first;
    return InkWell(
      onTap: _readOnly ? null : () => _addPhoto(caption: 'cover'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD6D3F0),
            style: BorderStyle.solid,
            width: 1.5,
          ),
          color: const Color(0xFFF7F6FF),
        ),
        clipBehavior: Clip.antiAlias,
        child: cover == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: _purple, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Add Place Photo',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: _purple,
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  _photoImage(cover),
                  const Positioned(
                    right: 8,
                    bottom: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit_outlined, size: 16),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _section(AuditSectionDef section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(section.title, scoreId: section.id),
        Text(
          section.subtitle,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        for (final item in section.items) _item(section, item),
        if (section.photos) ...[
          const SizedBox(height: 8),
          _photoStrip(section.id),
        ],
      ],
    );
  }

  Widget _item(AuditSectionDef section, AuditItemDef item) {
    final key = '${section.id}.${item.id}';
    return switch (item.kind) {
      AuditFieldKind.toggle => _toggleRow(section.id, item),
      AuditFieldKind.counter => _counter(item.label, key),
      AuditFieldKind.dropdown => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _dropdown(
          item.label,
          item.options!.contains(_field(key)) ? _field(key) : null,
          item.options!,
          (v) => _setField(key, v ?? ''),
        ),
      ),
      AuditFieldKind.text => _input(
        item.label,
        _field(key),
        (v) => _setField(key, v),
        hint: item.suffix,
      ),
    };
  }

  Widget _toggleRow(String sectionId, AuditItemDef item) {
    final selected = _draft.answerFor(sectionId, item.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(item.id), size: 20, color: _purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final a in const ['yes', 'no', 'na']) ...[
                Expanded(
                  child: _ynChip(
                    label: a == 'na' ? 'N/A' : (a == 'yes' ? 'Yes' : 'No'),
                    selected: selected == a,
                    onTap: () => _setAnswer(sectionId, item.id, a),
                  ),
                ),
                if (a != 'na') const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _ynChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? _purple : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: _readOnly ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }

  Widget _counter(String label, String key) {
    final n = int.tryParse(_field(key)) ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
          _roundIcon(
            Icons.remove,
            () => _setField(key, '${math.max(0, n - 1)}'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$n',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          _roundIcon(Icons.add, () => _setField(key, '${n + 1}')),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: _readOnly ? null : onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 18, color: _purple),
      ),
    );
  }

  Widget _photoStrip(String sectionId) {
    final photos = _draft.photos.where((p) => p.caption == sectionId).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Photos (Required)',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 84,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final p in photos)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: _photoImage(p),
                    ),
                  ),
                ),
              InkWell(
                onTap: _readOnly ? null : () => _addPhoto(caption: sectionId),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD6D3F0)),
                    color: const Color(0xFFF7F6FF),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: _purple),
                      Text(
                        'Add Photo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _servicesEmergency() {
    final staff = AuditCatalog.section('staff');
    final emergency = AuditCatalog.section('emergency');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Services, Staff & Emergency', scoreId: 'staff'),
        Text(
          staff.title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(height: 8),
        for (final item in staff.items)
          _checkRow(staff.id, item, const Color(0xFF16A34A)),
        const SizedBox(height: 16),
        Text(
          emergency.title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: const Color(0xFFDC2626),
          ),
        ),
        const SizedBox(height: 8),
        for (final item in emergency.items)
          _checkRow(emergency.id, item, const Color(0xFFDC2626)),
      ],
    );
  }

  Widget _checkRow(String sectionId, AuditItemDef item, Color color) {
    final selected = _draft.answerFor(sectionId, item.id);
    final on = selected == 'yes';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: on ? color.withValues(alpha: 0.08) : const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _readOnly
              ? null
              : () => _setAnswer(sectionId, item.id, on ? 'no' : 'yes'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(_iconFor(item.id), color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  on ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: on ? color : const Color(0xFFD1D5DB),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _review() {
    final scored = _computed;
    final cover = _draft.photos.isEmpty ? null : _draft.photos.first;
    final date = _draft.updatedAt ?? DateTime.now();
    const reviewRows = [
      ('parking', 'Parking'),
      ('entrance', 'Entrance'),
      ('mobility', 'Mobility'),
      ('toilet', 'Toilet'),
      ('visual', 'Visual'),
      ('hearing', 'Hearing'),
      ('cognitive', 'Cognitive'),
      ('staff', 'Services'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Review & Submit'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: cover == null
                      ? ColoredBox(
                          color: AppColors.primaryLight,
                          child: Icon(Icons.place_rounded, color: _purple),
                        )
                      : _photoImage(cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _draft.placeName.isEmpty
                          ? 'Untitled place'
                          : _draft.placeName,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${_draft.category} · ${_draft.placeAddress}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${date.day}/${date.month}/${date.year} · ${_draft.auditorName}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: 168,
            height: 168,
            child: CustomPaint(
              painter: _ScoreRingPainter(scored.score / 100, _purple),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${scored.score}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    Text(
                      AccessibilityAudit(
                        id: '',
                        uid: '',
                        auditorName: '',
                        placeId: '',
                        placeName: '',
                        placeAddress: '',
                        category: '',
                        score: scored.score,
                      ).scoreLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: _purple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= (scored.score / 20).round()
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFFF59E0B),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final row in reviewRows)
              Container(
                width: (MediaQuery.sizeOf(context).width - 56) / 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.$2,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '${scored.sections[row.$1] ?? 0}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        color: _purple,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _draft.confirmed,
          onChanged: _readOnly
              ? null
              : (v) => setState(
                  () => _draft = _draft.copyWith(confirmed: v == true),
                ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'I confirm that the information provided is accurate.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _input(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        maxLines: maxLines,
        enabled: !_readOnly,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF8F9FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) => setState(() => onChanged(v)),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8F9FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        items: [
          for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
        ],
        onChanged: _readOnly ? null : onChanged,
      ),
    );
  }

  Widget _photoImage(AuditPhoto photo) {
    if (photo.isNetwork) {
      return DecodedNetworkImage(
        photo.uri,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: Color(0xFFEEF0FF),
          child: Icon(Icons.broken_image_outlined),
        ),
      );
    }
    if (kIsWeb) {
      return const ColoredBox(
        color: Color(0xFFEEF0FF),
        child: Icon(Icons.image_outlined),
      );
    }
    return Image.file(
      File(photo.uri),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFEEF0FF),
        child: Icon(Icons.broken_image_outlined),
      ),
    );
  }

  IconData _iconFor(String id) {
    return switch (id) {
      'available' => Icons.local_parking_rounded,
      'kerbRamp' => Icons.accessible_forward_rounded,
      'dropOff' => Icons.hail_rounded,
      'marked' => Icons.signpost_outlined,
      'stepFree' => Icons.accessible_rounded,
      'ramp' => Icons.trending_up_rounded,
      'elevator' || 'elevatorControls' => Icons.elevator_rounded,
      'routeThroughout' => Icons.route_rounded,
      'corridors' => Icons.straighten_rounded,
      'turning' => Icons.sync_rounded,
      'counters' => Icons.desk_rounded,
      'seating' => Icons.event_seat_rounded,
      'handrails' || 'altStairs' => Icons.stairs_rounded,
      'floorSafe' => Icons.layers_rounded,
      'obstacles' || 'obstaclesMarked' => Icons.warning_amber_rounded,
      'restAreas' => Icons.weekend_rounded,
      'grabRails' => Icons.sports_gymnastics_rounded,
      'transfer' => Icons.swap_horiz_rounded,
      'sink' => Icons.countertops_rounded,
      'alarm' => Icons.emergency_rounded,
      'babyChange' => Icons.child_friendly_rounded,
      'signage' => Icons.info_outline_rounded,
      'tactile' || 'braille' => Icons.touch_app_rounded,
      'contrast' || 'stairEdge' => Icons.contrast_rounded,
      'largePrint' => Icons.text_fields_rounded,
      'lighting' => Icons.light_mode_outlined,
      'audible' => Icons.volume_up_rounded,
      'guideDog' || 'serviceAnimal' => Icons.pets_rounded,
      'loop' => Icons.hearing_rounded,
      'captions' => Icons.closed_caption_rounded,
      'visualAnnouncements' => Icons.campaign_outlined,
      'signLanguage' => Icons.front_hand_rounded,
      'staffTraining' || 'awareness' => Icons.school_outlined,
      'textChat' => Icons.chat_bubble_outline_rounded,
      'emergencyAlerts' => Icons.notifications_active_outlined,
      'quietArea' || 'quiet' || 'lowSensory' => Icons.nights_stay_rounded,
      'simpleSignage' ||
      'easyInstructions' ||
      'visualInstructions' => Icons.short_text_rounded,
      'navigation' || 'layout' => Icons.explore_outlined,
      'crowding' => Icons.groups_outlined,
      'flexibleWait' || 'priority' => Icons.schedule_rounded,
      'wheelchairAssist' => Icons.accessible_rounded,
      'personalAssist' => Icons.support_agent_rounded,
      'formats' => Icons.menu_book_outlined,
      'exits' => Icons.exit_to_app_rounded,
      'visualAlarms' || 'audibleAlarms' => Icons.alarm_rounded,
      'evacAssist' || 'refuge' => Icons.health_and_safety_outlined,
      _ => Icons.check_circle_outline_rounded,
    };
  }
}

class _StepStrip extends StatelessWidget {
  const _StepStrip({required this.current, required this.onTap});

  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          for (var i = 0; i < 10; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: i <= current
                      ? const Color(0xFF5B4BDB)
                      : const Color(0xFFE5E7EB),
                ),
              ),
            GestureDetector(
              onTap: () => onTap(i),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: i == current
                    ? const Color(0xFF5B4BDB)
                    : i < current
                    ? const Color(0xFFDDD9FF)
                    : const Color(0xFFF3F4F6),
                child: Text(
                  '${i + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: i == current
                        ? Colors.white
                        : const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  _ScoreRingPainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 10;
    final bg = Paint()
      ..color = const Color(0xFFEEF0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12;
    canvas.drawCircle(c, r, bg);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
