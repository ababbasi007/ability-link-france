import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_profile.dart';
import '../../services/address_book_service.dart';
import '../../services/background_task.dart';
import '../../theme/app_colors.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key, this.profile});

  final UserProfile? profile;

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _book = AddressBookService();

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    if (p != null) {
      runInBackground(
        _book.seedFromProfile(
          address: (p.contact['address'] as String?) ?? '',
          city: (p.contact['city'] as String?) ?? '',
          postalCode: (p.contact['postalCode'] as String?) ?? '',
          country: (p.contact['country'] as String?) ?? '',
        ),
        'seed address book',
      );
    }
  }

  Future<void> _edit({SavedAddress? existing}) async {
    final label = TextEditingController(text: existing?.label ?? 'Home');
    final line1 = TextEditingController(text: existing?.line1 ?? '');
    final city = TextEditingController(text: existing?.city ?? '');
    final postal = TextEditingController(text: existing?.postalCode ?? '');
    final country = TextEditingController(text: existing?.country ?? 'France');
    var isDefault = existing?.isDefault ?? false;
    try {
      final ok = await showModalBottomSheet<bool>(
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        existing == null ? 'Add address' : 'Edit address',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: label,
                        decoration: const InputDecoration(
                          labelText: 'Label (Home, Work…)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: line1,
                        decoration: const InputDecoration(
                          labelText: 'Street address',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: city,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: postal,
                        decoration: const InputDecoration(
                          labelText: 'Postal code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: country,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Default address'),
                        subtitle: const Text(
                          'Also updates your Passport contact details',
                        ),
                        value: isDefault,
                        onChanged: (v) => setModal(() => isDefault = v),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Save address'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
      if (ok != true) return;
      await _book.save(
        id: existing?.id,
        label: label.text,
        line1: line1.text,
        city: city.text,
        postalCode: postal.text,
        country: country.text,
        isDefault: isDefault,
      );
    } finally {
      label.dispose();
      line1.dispose();
      city.dispose();
      postal.dispose();
      country.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Saved addresses',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add'),
      ),
      body: StreamBuilder<List<SavedAddress>>(
        stream: _book.watch(),
        builder: (context, snap) {
          final list = snap.data ?? const <SavedAddress>[];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No saved addresses yet. Add home, work, or a care location.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = list[i];
              return Dismissible(
                key: ValueKey(a.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: const Color(0xFFEF4444),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => _book.delete(a.id),
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      a.isDefault
                          ? Icons.home_rounded
                          : Icons.location_on_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      a.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      a.summary.isEmpty ? 'No street details' : a.summary,
                    ),
                    trailing: a.isDefault
                        ? Text(
                            'Default',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                    onTap: () => _edit(existing: a),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
