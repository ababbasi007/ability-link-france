import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/service_provider.dart';
import '../../services/assistance_service.dart';
import '../../theme/app_colors.dart';

Future<bool?> showAssistanceBookingSheet(
  BuildContext context, {
  required ServiceProvider provider,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => AssistanceBookingSheet(provider: provider),
  );
}

class AssistanceBookingSheet extends StatefulWidget {
  const AssistanceBookingSheet({super.key, required this.provider});

  final ServiceProvider provider;

  @override
  State<AssistanceBookingSheet> createState() => _AssistanceBookingSheetState();
}

class _AssistanceBookingSheetState extends State<AssistanceBookingSheet> {
  final _assist = AssistanceService();
  final _notes = TextEditingController();
  late String _service;
  late DateTime _start;
  late List<DateTime> _slots;
  String _mode = 'in_person';
  bool _payNow = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _service = widget.provider.services.isNotEmpty
        ? widget.provider.services.first
        : widget.provider.specialty;
    _slots = _assist.scheduleSlotsFor(widget.provider);
    _start = _slots.isNotEmpty
        ? _slots.first
        : DateTime.now().add(const Duration(days: 1, hours: 2));
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickCustom() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time == null) return;
    setState(() {
      _start = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await _assist.bookAssistance(
        provider: widget.provider,
        startAt: _start,
        mode: _mode,
        service: _service,
        notes: _notes.text,
        payNow: _payNow,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _payNow
                ? 'Booked and paid (sandbox). See Booking history.'
                : 'Assistance booked. Pay later from Billing.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Book assistance',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${p.name} · ${p.priceLabel}/hr',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _service,
              decoration: const InputDecoration(
                labelText: 'Service',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final s
                    in (p.services.isEmpty ? [p.specialty] : p.services))
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _service = v);
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Schedule',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slot in _slots.take(6))
                  ChoiceChip(
                    selected: _start == slot,
                    label: Text(
                      '${slot.month}/${slot.day} '
                      '${TimeOfDay.fromDateTime(slot).format(context)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onSelected: (_) => setState(() => _start = slot),
                    selectedColor: AppColors.primaryLight,
                  ),
                ActionChip(
                  label: const Text('Custom…'),
                  onPressed: _pickCustom,
                ),
              ],
            ),
            if (p.availabilitySlots.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Usual windows: ${p.availabilitySlots.join(' · ')}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _mode,
              decoration: const InputDecoration(
                labelText: 'Mode',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'in_person', child: Text('In person')),
                DropdownMenuItem(
                  value: 'remote_video',
                  child: Text('Remote video'),
                ),
                DropdownMenuItem(
                  value: 'remote_chat',
                  child: Text('Remote chat'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _mode = v);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Accessibility needs / notes',
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Pay now (sandbox)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Test gateway · no card numbers stored · ${p.priceLabel}',
                style: GoogleFonts.plusJakartaSans(fontSize: 12),
              ),
              value: _payNow,
              onChanged: (v) => setState(() => _payNow = v),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(
                _submitting
                    ? 'Booking…'
                    : (_payNow
                          ? 'Book & pay ${p.priceLabel}'
                          : 'Book without pay'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
