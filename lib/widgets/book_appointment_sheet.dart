import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/service_provider.dart';
import '../services/healthcare_service.dart';
import '../theme/app_colors.dart';

class BookAppointmentSheet extends StatefulWidget {
  const BookAppointmentSheet({super.key, required this.provider});

  final ServiceProvider provider;

  static Future<bool?> show(
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
      builder: (_) => BookAppointmentSheet(provider: provider),
    );
  }

  @override
  State<BookAppointmentSheet> createState() => _BookAppointmentSheetState();
}

class _BookAppointmentSheetState extends State<BookAppointmentSheet> {
  final _notes = TextEditingController();
  final _care = HealthcareService();
  late DateTime _start;
  String _mode = 'video';
  bool _submitting = false;
  bool _payNow = true;
  late List<DateTime> _slots;

  @override
  void initState() {
    super.initState();
    _slots = _care.slotsFor(widget.provider);
    _start = _slots.isNotEmpty
        ? _slots.first
        : DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
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
      await _care.book(
        provider: widget.provider,
        startAt: _start,
        mode: _mode,
        notes: _notes.text.trim(),
        payNow: _payNow,
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
              'Book appointment',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${p.name} · ${p.specialty}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [
                for (final m in [
                  ('video', 'Video'),
                  ('audio', 'Audio'),
                  ('chat', 'Chat'),
                  ('in-clinic', 'In clinic'),
                  ('home', 'Home visit'),
                ])
                  ChoiceChip(
                    label: Text(m.$2),
                    selected: _mode == m.$1,
                    onSelected: (_) => setState(() => _mode = m.$1),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.provider.availableNow
                  ? 'Open slots this week'
                  : 'Scheduled slots (not available now)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _slots)
                  ChoiceChip(
                    label: Text(
                      '${s.month}/${s.day} ${s.hour.toString().padLeft(2, '0')}:00',
                    ),
                    selected: _start == s,
                    onSelected: (_) => setState(() => _start = s),
                  ),
              ],
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule, color: AppColors.primary),
              title: Text(
                _start.toLocal().toString().substring(0, 16),
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Or pick a custom date & time'),
              onTap: _pickDate,
            ),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Accessibility needs for this visit',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pay now (sandbox)'),
              subtitle: Text('Test gateway · ${p.priceLabel} · no card stored'),
              value: _payNow,
              onChanged: (v) => setState(() => _payNow = v),
            ),
            const SizedBox(height: 8),
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
                        _payNow
                            ? 'Book & pay ${p.priceLabel}'
                            : 'Confirm booking',
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
