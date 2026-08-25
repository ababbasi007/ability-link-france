import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/place.dart';
import '../services/ai_tools_service.dart';
import '../services/auth_service.dart';
import '../services/voice_service.dart';
import '../theme/app_colors.dart';

Future<void> showPlaceAiSummary(
  BuildContext context,
  AccessiblePlace place,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
    ),
  );

  try {
    final profile = await AuthService().getCurrentProfile();
    final result = await AiToolsService().summarizePlace(
      place,
      profile: profile,
    );
    if (!context.mounted) return;
    Navigator.of(context).pop(); // loading
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          result.title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Text(
            result.text,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: result.text));
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => VoiceService.instance.speak(result.text),
            child: const Text('Listen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not summarize: $e')));
  }
}
