import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/travel_destination.dart';
import '../../services/travel_service.dart';
import '../../theme/app_colors.dart';

Future<bool?> showTravelBookingSheet(
  BuildContext context, {
  required TravelDestination destination,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => TravelBookingSheet(destination: destination),
  );
}

class TravelBookingSheet extends StatefulWidget {
  const TravelBookingSheet({super.key, required this.destination});

  final TravelDestination destination;

  @override
  State<TravelBookingSheet> createState() => _TravelBookingSheetState();
}

class _TravelBookingSheetState extends State<TravelBookingSheet> {
  final _travel = TravelService();
  final _notes = TextEditingController();
  late String _service;
  late DateTime _start;
  int _guests = 1;
  bool _payNow = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final d = widget.destination;
    _service = switch (d.kind) {
      'hotel' =>
        d.accessibleRooms.isNotEmpty
            ? d.accessibleRooms.first
            : 'Accessible room',
      'tour' => 'Guided accessible tour',
      'transport' => 'Accessible transfer',
      'restaurant' => 'Accessible table',
      _ => 'Accessible visit',
    };
    _start = DateTime.now().add(const Duration(days: 1, hours: 3));
    _start = DateTime(_start.year, _start.month, _start.day, 11);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
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
      await _travel.bookService(
        destination: widget.destination,
        startAt: _start,
        service: _service,
        notes: _notes.text,
        guests: _guests,
        payNow: _payNow,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.destination;
    final services = <String>{
      _service,
      ...d.accessibleRooms,
      if (d.kind == 'tour') 'Private accessible tour',
      if (d.kind == 'transport') 'Wheelchair van',
      if (d.kind == 'restaurant') 'Hearing-loop table',
      if (d.kind == 'attraction') 'Timed accessible entry',
    }.toList();

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
              'Book ${d.kindLabel.toLowerCase()}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${d.name} · ${d.bookPriceLabel}',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: services.contains(_service)
                  ? _service
                  : services.first,
              decoration: const InputDecoration(
                labelText: 'Service / room',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final s in services)
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _service = v);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'When',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${_start.month}/${_start.day}/${_start.year} · '
                '${TimeOfDay.fromDateTime(_start).format(context)}',
              ),
              trailing: TextButton(
                onPressed: _pickWhen,
                child: const Text('Change'),
              ),
            ),
            Row(
              children: [
                Text(
                  'Guests',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Fewer guests',
                  onPressed: _guests > 1
                      ? () => setState(() => _guests--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_guests'),
                IconButton(
                  tooltip: 'More guests',
                  onPressed: _guests < 8
                      ? () => setState(() => _guests++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Accessibility needs',
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Pay now (sandbox)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Test gateway · no card numbers stored'),
              value: _payNow,
              onChanged: (v) => setState(() => _payNow = v),
            ),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(_submitting ? 'Booking…' : 'Confirm booking'),
            ),
          ],
        ),
      ),
    );
  }
}
