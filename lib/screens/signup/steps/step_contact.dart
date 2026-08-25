import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../signup_data.dart';
import '../signup_flow_screen.dart';
import '../signup_shared.dart';

class StepContact extends StatelessWidget {
  const StepContact({
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
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      step: 3,
      title: 'Contact Information',
      subtitle: 'How can we contact you?',
      onBack: onBack,
      onNext: onNext,
      onSkip: onSkip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 100,
                child: SignupDropdown(
                  hint: 'Code',
                  value: data.countryCode,
                  items: const ['+33', '+32', '+41', '+1', '+44'],
                  onChanged: (v) {
                    if (v != null) {
                      data.countryCode = v;
                      onChanged();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SignupTextField(
                  hint: 'Mobile Number',
                  icon: Icons.phone_outlined,
                  initialValue: data.mobile,
                  keyboardType: TextInputType.phone,
                  onChanged: (v) => data.mobile = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SignupTextField(
            hint: 'Email Address',
            icon: Icons.email_outlined,
            initialValue: data.email,
            keyboardType: TextInputType.emailAddress,
            onChanged: (v) => data.email = v,
          ),
          const SizedBox(height: 12),
          SignupDropdown(
            hint: 'Country',
            icon: Icons.flag_outlined,
            value: data.country,
            items: const [
              'United States',
              'United Kingdom',
              'Canada',
              'United Arab Emirates',
              'India',
              'Pakistan',
              'Other',
            ],
            onChanged: (v) {
              if (v != null) {
                data.country = v;
                onChanged();
              }
            },
          ),
          const SizedBox(height: 12),
          SignupDropdown(
            hint: 'City',
            icon: Icons.location_city_outlined,
            value: data.city,
            items: const [
              'New York',
              'London',
              'Toronto',
              'Dubai',
              'Mumbai',
              'Karachi',
              'Other',
            ],
            onChanged: (v) {
              if (v != null) {
                data.city = v;
                onChanged();
              }
            },
          ),
          const SizedBox(height: 12),
          SignupTextField(
            hint: 'Home Address',
            icon: Icons.home_outlined,
            initialValue: data.address,
            onChanged: (v) => data.address = v,
          ),
          const SizedBox(height: 12),
          SignupTextField(
            hint: 'Postal Code',
            icon: Icons.markunread_mailbox_outlined,
            initialValue: data.postalCode,
            keyboardType: TextInputType.number,
            onChanged: (v) => data.postalCode = v,
          ),
          const SizedBox(height: 20),
          Text(
            'Emergency Contact',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Someone we can reach in case of emergency',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          SignupTextField(
            hint: 'Full Name',
            icon: Icons.person_outline_rounded,
            initialValue: data.emergencyName,
            onChanged: (v) => data.emergencyName = v,
          ),
          const SizedBox(height: 12),
          SignupDropdown(
            hint: 'Relationship',
            icon: Icons.favorite_border_rounded,
            value: data.emergencyRelation,
            items: const [
              'Sister',
              'Brother',
              'Parent',
              'Spouse',
              'Friend',
              'Other',
            ],
            onChanged: (v) {
              if (v != null) {
                data.emergencyRelation = v;
                onChanged();
              }
            },
          ),
          const SizedBox(height: 12),
          SignupTextField(
            hint: 'Phone Number',
            icon: Icons.phone_outlined,
            initialValue: data.emergencyPhone,
            keyboardType: TextInputType.phone,
            onChanged: (v) => data.emergencyPhone = v,
          ),
        ],
      ),
    );
  }
}
