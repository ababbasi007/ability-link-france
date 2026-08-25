import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/service_provider.dart';
import '../../services/providers_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/decoded_network_image.dart';
import '../../widgets/book_appointment_sheet.dart';
import '../../widgets/reviews_section.dart';
import '../assistance/assistance_booking_sheet.dart';
import '../assistance/assistance_chat_screens.dart';
import '../caregiver/caregiver_tools_screens.dart';
import '../../data/assistance_taxonomy.dart';
import '../../services/assistance_service.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({
    super.key,
    required this.providerId,
    this.provider,
  });

  final String providerId;
  final ServiceProvider? provider;

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _service = ProvidersService();
  ServiceProvider? _provider;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.provider != null) {
      _provider = widget.provider;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      await _service.ensureSeeded();
      final p = await _service.getProvider(widget.providerId);
      if (!mounted) return;
      setState(() {
        _provider = p;
        _loading = false;
        if (p == null) _error = 'Provider not found';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openEnquiry() async {
    final provider = _provider;
    if (provider == null) return;

    final messageCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final slotCtrl = TextEditingController(text: 'Tomorrow afternoon');
    try {
      String service = provider.services.isNotEmpty
          ? provider.services.first
          : 'Consultation';
      var submitting = false;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModal) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  20 + MediaQuery.viewInsetsOf(ctx).bottom,
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
                        'Book / Enquire',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        provider.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: service,
                        decoration: const InputDecoration(
                          labelText: 'Service',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final s
                              in (provider.services.isEmpty
                                  ? ['Consultation']
                                  : provider.services))
                            DropdownMenuItem(value: s, child: Text(s)),
                        ],
                        onChanged: (v) {
                          if (v != null) setModal(() => service = v);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: slotCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Preferred time',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact phone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: messageCtrl,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Message / accessibility needs',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submitting
                              ? null
                              : () async {
                                  setModal(() => submitting = true);
                                  try {
                                    await _service.submitEnquiry(
                                      ProviderEnquiry(
                                        providerId: provider.id,
                                        providerName: provider.name,
                                        service: service,
                                        preferredSlot: slotCtrl.text.trim(),
                                        contactPhone: phoneCtrl.text.trim(),
                                        message: messageCtrl.text.trim().isEmpty
                                            ? 'I would like to book a session.'
                                            : messageCtrl.text.trim(),
                                      ),
                                    );
                                    if (!ctx.mounted) return;
                                    Navigator.pop(ctx);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Enquiry sent. The provider will follow up.',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    setModal(() => submitting = false);
                                    if (!ctx.mounted) return;
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Send enquiry',
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
            },
          );
        },
      );
    } finally {
      messageCtrl.dispose();
      phoneCtrl.dispose();
      slotCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final p = _provider;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: p.photoUrl.isEmpty
                  ? Container(color: AppColors.primaryLight)
                  : DecodedNetworkImage(
                      p.photoUrl,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: AppColors.primaryLight),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E1B4B),
                          ),
                        ),
                      ),
                      if (p.verified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${p.title.isEmpty ? '' : '${p.title} · '}${p.specialty}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _meta(
                        Icons.star_rounded,
                        '${p.rating} (${p.reviewCount})',
                      ),
                      _meta(Icons.payments_outlined, p.priceLabel),
                      _meta(Icons.place_outlined, p.city),
                      if (p.availableNow)
                        _meta(
                          Icons.circle,
                          'Available now',
                          color: const Color(0xFF22C55E),
                        ),
                      _meta(Icons.work_outline, '${p.yearsExperience} yrs'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Inline rather than a bottom bar: the app-wide
                  // navigation already occupies the bottom of every screen.
                  if (p.isAssistance)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final assist = AssistanceService();
                                await assist.ensureThread(provider: p);
                                if (!mounted) return;
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        AssistanceChatScreen(provider: p),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                size: 18,
                              ),
                              label: const Text('Message'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _reportAssistant(p),
                              icon: const Icon(Icons.flag_outlined, size: 18),
                              label: const Text('Report'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _openEnquiry,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Enquire',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      if (p.isAssistance) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await showCareHireSheet(context, provider: p);
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Hire',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            final provider = _provider;
                            if (provider == null) return;
                            if (provider.isAssistance) {
                              final ok = await showAssistanceBookingSheet(
                                context,
                                provider: provider,
                              );
                              if (ok == true && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Assistance booked.'),
                                  ),
                                );
                              }
                              return;
                            }
                            final ok = await BookAppointmentSheet.show(
                              context,
                              provider: provider,
                            );
                            if (ok != true || !mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Appointment booked.'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            p.isAssistance ? 'Book & pay' : 'Book appointment',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'About',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.bio,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.45,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Services',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in p.services)
                        Chip(
                          label: Text(s),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFF0F1F3)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Accessibility',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in p.accessibilityTags)
                        Chip(
                          label: Text(t),
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
                  const SizedBox(height: 12),
                  Text(
                    'Languages',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.languages.join(' · '),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (p.skills.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Skills',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in p.skills)
                          Chip(
                            label: Text(s),
                            backgroundColor: AppColors.primaryLight,
                            side: BorderSide.none,
                          ),
                      ],
                    ),
                  ],
                  if (p.assistanceType.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Assistance type: ${assistanceTypeLabel(p.assistanceType)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                  if (p.availabilitySlots.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Availability',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final slot in p.availabilitySlots)
                          Chip(
                            avatar: Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: p.availableNow
                                  ? const Color(0xFF22C55E)
                                  : AppColors.textSecondary,
                            ),
                            label: Text(slot),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFF0F1F3)),
                          ),
                      ],
                    ),
                  ],
                  if (p.verified) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Verification',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.checklist.isEmpty
                          ? 'Verified caregiver · credentials reviewed'
                          : '${p.checklistPercent}% accessibility checklist · credentials reviewed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ReviewsSection(
                    targetType: 'provider',
                    targetId: p.id,
                    targetName: p.name,
                    fallbackRating: p.rating,
                    fallbackCount: p.reviewCount,
                    listingVerified: p.verified,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reportAssistant(ServiceProvider provider) async {
    final detail = TextEditingController();
    var reason = 'Inappropriate behavior';
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModal) {
              return AlertDialog(
                title: const Text('Report assistant'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: reason,
                      items: const [
                        DropdownMenuItem(
                          value: 'Inappropriate behavior',
                          child: Text('Inappropriate behavior'),
                        ),
                        DropdownMenuItem(
                          value: 'No-show / unreliable',
                          child: Text('No-show / unreliable'),
                        ),
                        DropdownMenuItem(
                          value: 'Safety concern',
                          child: Text('Safety concern'),
                        ),
                        DropdownMenuItem(
                          value: 'Fraud / scam',
                          child: Text('Fraud / scam'),
                        ),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModal(() => reason = v);
                      },
                      decoration: const InputDecoration(labelText: 'Reason'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: detail,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Details',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Submit'),
                  ),
                ],
              );
            },
          );
        },
      );
      if (ok != true) return;
      await AssistanceService().reportAssistant(
        provider: provider,
        reason: reason,
        detail: detail.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted to moderators.')),
      );
    } finally {
      detail.dispose();
    }
  }

  Widget _meta(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color ?? const Color(0xFF1E1B4B),
          ),
        ),
      ],
    );
  }
}
