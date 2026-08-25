import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/passport_options.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../signup/signup_data.dart';
import '../signup/signup_shared.dart';
import '../signup/steps/step_communication.dart';

enum PassportEditSection {
  personal,
  needs,
  communication,
  assistance,
  mobility,
  medical,
  emergency,
}

class PassportEditScreen extends StatefulWidget {
  const PassportEditScreen({
    super.key,
    required this.profile,
    this.initialSection = PassportEditSection.needs,
  });

  final UserProfile profile;
  final PassportEditSection initialSection;

  @override
  State<PassportEditScreen> createState() => _PassportEditScreenState();
}

class _PassportEditScreenState extends State<PassportEditScreen> {
  final _auth = AuthService();
  late final SignupData _data;
  late PassportEditSection _section;
  bool _saving = false;

  static const _tabs = <(PassportEditSection, String)>[
    (PassportEditSection.personal, 'Personal'),
    (PassportEditSection.needs, 'Needs'),
    (PassportEditSection.communication, 'Communication'),
    (PassportEditSection.assistance, 'Assistance'),
    (PassportEditSection.mobility, 'Mobility'),
    (PassportEditSection.medical, 'Medical'),
    (PassportEditSection.emergency, 'Emergency'),
  ];

  @override
  void initState() {
    super.initState();
    _data = SignupData.fromProfile(widget.profile);
    _section = widget.initialSection;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _auth.updatePassport(_data);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passport updated')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_auth.messageFor(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Update Passport',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final (id, label) = _tabs[i];
                return ChoiceChip(
                  label: Text(label),
                  selected: _section == id,
                  onSelected: (_) => setState(() => _section = id),
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  'Passport ${widget.profile.passportId} · changes apply across matching, sharing, and SOS.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _sectionBody(),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Save Passport'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionBody() {
    switch (_section) {
      case PassportEditSection.personal:
        return _personal();
      case PassportEditSection.needs:
        return _needs();
      case PassportEditSection.communication:
        return CommunicationPrefsForm(
          data: _data,
          onChanged: () => setState(() {}),
        );
      case PassportEditSection.assistance:
        return _assistance();
      case PassportEditSection.mobility:
        return _mobility();
      case PassportEditSection.medical:
        return _medical();
      case PassportEditSection.emergency:
        return _emergency();
    }
  }

  Widget _personal() {
    return Column(
      children: [
        SignupTextField(
          hint: 'First Name',
          icon: Icons.person_outline_rounded,
          initialValue: _data.firstName,
          onChanged: (v) => _data.firstName = v,
        ),
        const SizedBox(height: 12),
        SignupTextField(
          hint: 'Last Name',
          icon: Icons.badge_outlined,
          initialValue: _data.lastName,
          onChanged: (v) => _data.lastName = v,
        ),
        const SizedBox(height: 12),
        SignupTextField(
          hint: 'Date of Birth (DD/MM/YYYY)',
          icon: Icons.calendar_today_outlined,
          initialValue: _data.dateOfBirth,
          readOnly: true,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(1992, 3, 15),
              firstDate: DateTime(1920),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _data.dateOfBirth =
                    '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
              });
            }
          },
        ),
        const SizedBox(height: 12),
        SignupDropdown(
          hint: 'Gender',
          icon: Icons.wc_rounded,
          value: _data.gender,
          items: PassportOptions.genders,
          onChanged: (v) {
            if (v != null) setState(() => _data.gender = v);
          },
        ),
        const SizedBox(height: 12),
        SignupDropdown(
          hint: 'Preferred Language',
          icon: Icons.translate_rounded,
          value: _data.preferredLanguage,
          items: PassportOptions.languages,
          onChanged: (v) {
            if (v != null) setState(() => _data.preferredLanguage = v);
          },
        ),
        const SizedBox(height: 12),
        SignupTextField(
          hint: 'Street address',
          icon: Icons.home_outlined,
          initialValue: _data.address,
          onChanged: (v) => _data.address = v,
        ),
        const SizedBox(height: 12),
        SignupTextField(
          hint: 'City',
          icon: Icons.location_city_outlined,
          initialValue: _data.city,
          onChanged: (v) => _data.city = v,
        ),
        const SizedBox(height: 12),
        SignupTextField(
          hint: 'Postal code',
          icon: Icons.markunread_mailbox_outlined,
          initialValue: _data.postalCode,
          keyboardType: TextInputType.streetAddress,
          onChanged: (v) => _data.postalCode = v,
        ),
        const SizedBox(height: 12),
        SignupDropdown(
          hint: 'Country',
          icon: Icons.flag_outlined,
          value: PassportOptions.countries.contains(_data.country)
              ? _data.country
              : 'Other',
          items: PassportOptions.countries,
          onChanged: (v) {
            if (v != null) setState(() => _data.country = v);
          },
        ),
        const SizedBox(height: 12),
        SignupTextField(
          hint: 'Mobile',
          icon: Icons.phone_outlined,
          initialValue: _data.mobile,
          keyboardType: TextInputType.phone,
          onChanged: (v) => _data.mobile = v,
        ),
      ],
    );
  }

  Widget _needs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What best describes you? Select all that apply.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: PassportOptions.profiles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, i) {
            final item = PassportOptions.profiles[i];
            final selected = _data.accessibilityProfiles.contains(item.$2);
            return SelectableIconCard(
              icon: item.$1,
              label: item.$2,
              selected: selected,
              onTap: () {
                setState(() {
                  if (selected) {
                    _data.accessibilityProfiles.remove(item.$2);
                  } else {
                    _data.accessibilityProfiles.add(item.$2);
                  }
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _assistance() {
    return Column(
      children: [
        for (final label in PassportOptions.assistanceNeeds)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _data.assistanceNeeds.contains(label),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _data.assistanceNeeds.add(label);
                } else {
                  _data.assistanceNeeds.remove(label);
                }
              });
            },
            title: Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
            ),
          ),
        SignupTextField(
          hint: 'Additional requirements',
          maxLines: 3,
          initialValue: _data.additionalRequirements,
          onChanged: (v) => _data.additionalRequirements = v,
        ),
      ],
    );
  }

  Widget _mobility() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobility aid',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: PassportOptions.mobilityAids.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, i) {
            final aid = PassportOptions.mobilityAids[i];
            return SelectableIconCard(
              icon: aid.$1,
              label: aid.$2,
              selected: _data.mobilityAid == aid.$2,
              compact: true,
              onTap: () => setState(() => _data.mobilityAid = aid.$2),
            );
          },
        ),
        const SizedBox(height: 16),
        YesNoToggle(
          label: 'Need accessible transport?',
          value: _data.needAccessibleTransport,
          onChanged: (v) => setState(() => _data.needAccessibleTransport = v),
        ),
        YesNoToggle(
          label: 'Need elevator access?',
          value: _data.needElevator,
          onChanged: (v) => setState(() => _data.needElevator = v),
        ),
        YesNoToggle(
          label: 'Need accessible toilet?',
          value: _data.needAccessibleToilet,
          onChanged: (v) => setState(() => _data.needAccessibleToilet = v),
        ),
        YesNoToggle(
          label: 'Need caregiver?',
          value: _data.needCaregiver,
          onChanged: (v) => setState(() => _data.needCaregiver = v),
        ),
        YesNoToggle(
          label: 'Need service animal accommodation?',
          value: _data.needServiceAnimal,
          onChanged: (v) => setState(() => _data.needServiceAnimal = v),
        ),
      ],
    );
  }

  Widget _medical() {
    return Column(
      children: [
        SignupTextField(
          hint: 'Doctor / Physician',
          icon: Icons.medical_services_outlined,
          initialValue: _data.doctor,
          onChanged: (v) => _data.doctor = v,
        ),
        const SizedBox(height: 12),
        SignupTextField(
          hint: 'Hospital / Clinic',
          icon: Icons.local_hospital_outlined,
          initialValue: _data.hospital,
          onChanged: (v) => _data.hospital = v,
        ),
        const SizedBox(height: 12),
        SignupTextField(
          hint: 'Medical Conditions',
          icon: Icons.healing_outlined,
          initialValue: _data.conditions,
          onChanged: (v) => _data.conditions = v,
        ),
        const SizedBox(height: 12),
        SignupTextField(
          hint: 'Allergies',
          icon: Icons.warning_amber_rounded,
          initialValue: _data.allergies,
          onChanged: (v) => _data.allergies = v,
        ),
        const SizedBox(height: 12),
        SignupTextField(
          hint: 'Current Medications',
          icon: Icons.medication_outlined,
          initialValue: _data.medications,
          onChanged: (v) => _data.medications = v,
        ),
        const SizedBox(height: 12),
        SignupDropdown(
          hint: 'Blood Group',
          icon: Icons.bloodtype_outlined,
          value: _data.bloodGroup,
          items: PassportOptions.bloodGroups,
          onChanged: (v) {
            if (v != null) setState(() => _data.bloodGroup = v);
          },
        ),
        const SizedBox(height: 12),
        SignupDropdown(
          hint: 'Insurance',
          icon: Icons.verified_user_outlined,
          value: _data.insurance,
          items: PassportOptions.insurance,
          onChanged: (v) {
            if (v != null) setState(() => _data.insurance = v);
          },
        ),
        const SizedBox(height: 12),
        SignupTextField(
          hint: 'Emergency medical notes for first responders…',
          maxLines: 3,
          initialValue: _data.emergencyNotes,
          onChanged: (v) => _data.emergencyNotes = v,
        ),
      ],
    );
  }

  Widget _emergency() {
    return Column(
      children: [
        SignupTextField(
          hint: 'Emergency contact name',
          icon: Icons.person_outline,
          initialValue: _data.emergencyName,
          onChanged: (v) => _data.emergencyName = v,
        ),
        const SizedBox(height: 12),
        SignupDropdown(
          hint: 'Relation',
          icon: Icons.family_restroom_outlined,
          value: PassportOptions.relations.contains(_data.emergencyRelation)
              ? _data.emergencyRelation
              : 'Other',
          items: PassportOptions.relations,
          onChanged: (v) {
            if (v != null) setState(() => _data.emergencyRelation = v);
          },
        ),
        const SizedBox(height: 12),
        SignupTextField(
          hint: 'Emergency phone',
          icon: Icons.phone_outlined,
          initialValue: _data.emergencyPhone,
          keyboardType: TextInputType.phone,
          onChanged: (v) => _data.emergencyPhone = v,
        ),
      ],
    );
  }
}
