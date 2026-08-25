import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/passport_share.dart';
import '../../services/passport_share_service.dart';
import '../../theme/app_colors.dart';

class PassportViewScreen extends StatefulWidget {
  const PassportViewScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  State<PassportViewScreen> createState() => _PassportViewScreenState();
}

class _PassportViewScreenState extends State<PassportViewScreen> {
  final _code = TextEditingController();
  final _service = PassportShareService();
  PassportShare? _share;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCode;
    if (initial != null && initial.isNotEmpty) {
      _code.text = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final share = await _service.openShare(_code.text);
      if (!mounted) return;
      setState(() {
        _share = share;
        _loading = false;
        if (share == null) {
          _error = 'Code not found.';
        } else if (!share.isActive) {
          _error = 'This share is revoked or expired.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final snap = _share?.snapshot ?? const <String, dynamic>{};
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'View shared Passport',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Share code',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _loading ? null : _open,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(_loading ? 'Opening…' : 'Open with consent log'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFEF4444))),
          ],
          if (_share != null && _share!.isActive) ...[
            const SizedBox(height: 16),
            Text(
              'Shared fields',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final e in snap.entries)
              if (e.value != null && '${e.value}'.trim().isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    e.key,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  subtitle: Text(
                    e.value is List
                        ? (e.value as List).join(', ')
                        : '${e.value}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
