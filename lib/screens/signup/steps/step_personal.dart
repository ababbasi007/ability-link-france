import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/profile_media_service.dart';
import '../../../theme/app_colors.dart';
import '../signup_data.dart';
import '../signup_flow_screen.dart';
import '../signup_shared.dart';

class StepPersonal extends StatefulWidget {
  const StepPersonal({
    super.key,
    required this.data,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.onChanged,
  });

  final SignupData data;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onChanged;

  @override
  State<StepPersonal> createState() => _StepPersonalState();
}

class _StepPersonalState extends State<StepPersonal> {
  final _media = ProfileMediaService();
  bool _uploading = false;

  SignupData get data => widget.data;

  Future<void> _pickPhoto() async {
    setState(() => _uploading = true);
    try {
      final url = await _media.pickFromSheet(context);
      if (url != null && mounted) widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = FirebaseAuth.instance.currentUser?.photoURL;
    return SignupStepScaffold(
      step: 2,
      title: 'Personal Information',
      subtitle: 'Tell us a bit about yourself.',
      onBack: widget.onBack,
      onNext: widget.onNext,
      onSkip: widget.onSkip,
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _uploading ? null : _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: photo != null && photo.isNotEmpty
                            ? NetworkImage(photo)
                            : const AssetImage('assets/images/avatar.png')
                                  as ImageProvider,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: _uploading
                              ? const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  photo != null && photo.isNotEmpty
                      ? 'Change photo'
                      : 'Add Photo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SignupTextField(
            hint: 'First Name',
            icon: Icons.person_outline_rounded,
            initialValue: data.firstName,
            onChanged: (v) => data.firstName = v,
          ),
          const SizedBox(height: 12),
          SignupTextField(
            hint: 'Last Name',
            icon: Icons.badge_outlined,
            initialValue: data.lastName,
            onChanged: (v) => data.lastName = v,
          ),
          const SizedBox(height: 12),
          SignupTextField(
            hint: 'Date of Birth (DD/MM/YYYY)',
            icon: Icons.calendar_today_outlined,
            initialValue: data.dateOfBirth,
            readOnly: true,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(1992, 3, 15),
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                data.dateOfBirth =
                    '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                widget.onChanged();
              }
            },
          ),
          const SizedBox(height: 12),
          SignupDropdown(
            hint: 'Gender',
            icon: Icons.wc_rounded,
            value: data.gender,
            items: const ['Female', 'Male', 'Non-binary', 'Prefer not to say'],
            onChanged: (v) {
              if (v != null) {
                data.gender = v;
                widget.onChanged();
              }
            },
          ),
          const SizedBox(height: 12),
          SignupDropdown(
            hint: 'Nationality',
            icon: Icons.public_rounded,
            value: data.nationality,
            items: const [
              'American',
              'British',
              'Canadian',
              'Emirati',
              'Indian',
              'Pakistani',
              'Other',
            ],
            onChanged: (v) {
              if (v != null) {
                data.nationality = v;
                widget.onChanged();
              }
            },
          ),
          const SizedBox(height: 12),
          SignupDropdown(
            hint: 'Preferred Language',
            icon: Icons.translate_rounded,
            value: data.preferredLanguage,
            items: const ['English', 'French', 'Arabic', 'Spanish'],
            onChanged: (v) {
              if (v != null) {
                data.preferredLanguage = v;
                widget.onChanged();
              }
            },
          ),
        ],
      ),
    );
  }
}
