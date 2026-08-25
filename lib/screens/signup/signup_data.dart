import '../../models/user_profile.dart';

class SignupData {
  String? role;

  String firstName = '';
  String lastName = '';
  String dateOfBirth = '';
  String gender = 'Female';
  String nationality = 'Other';
  String preferredLanguage = 'English';

  String countryCode = '+1';
  String mobile = '';
  String email = '';
  String country = 'United States';
  String city = 'New York';
  String address = '';
  String postalCode = '';
  String emergencyName = '';
  String emergencyRelation = 'Sister';
  String emergencyPhone = '';

  final Set<String> accessibilityProfiles = {'Mobility'};
  final Set<String> assistanceNeeds = {
    'Personal Assistant',
    'Guide Assistant',
    'Sign Language Interpreter',
    'Wheelchair Assistance',
    'Caregiver',
    'Transportation',
  };
  String additionalRequirements = '';

  final Set<String> communicationModes = {'Spoken conversation'};
  String signLanguage = 'None';
  String preferredContactMethod = 'Voice call';
  bool needsCaptions = false;
  bool needsInterpreter = false;
  bool easyRead = false;
  String communicationNotes = '';

  String mobilityAid = 'Wheelchair';
  bool needAccessibleTransport = true;
  bool needElevator = false;
  bool needAccessibleToilet = true;
  bool needCaregiver = true;
  bool needServiceAnimal = false;

  String doctor = '';
  String hospital = '';
  String conditions = '';
  String allergies = '';
  String medications = '';
  String bloodGroup = 'O+';
  String insurance = 'Private';
  String emergencyNotes = '';

  bool largeText = true;
  bool voiceNavigation = false;
  bool darkMode = false;
  bool highContrast = false;
  bool screenReader = false;
  bool hapticFeedback = true;
  bool captions = true;
  bool simpleLanguage = false;
  double textSize = 1.0;

  final Set<String> interestedServices = {
    'Accessibility Map',
    'Telehealth',
    'AI Assistant',
  };
  bool medReminders = true;
  bool appointmentReminders = true;
  bool nearbyPlaces = true;
  bool benefitUpdates = false;

  String get fullName => '$firstName $lastName'.trim();

  String get passportId {
    final stamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return 'AL-$stamp';
  }

  String get communicationSummary {
    final parts = <String>[
      if (communicationModes.isNotEmpty) communicationModes.join(', '),
      if (signLanguage != 'None') signLanguage,
      if (needsInterpreter) 'Interpreter',
      if (needsCaptions) 'Captions',
      if (easyRead) 'Easy-read',
      preferredContactMethod,
    ];
    return parts.join(' · ');
  }

  Map<String, dynamic> communicationMap() => {
    'modes': communicationModes.toList(),
    'signLanguage': signLanguage,
    'preferredContactMethod': preferredContactMethod,
    'needsCaptions': needsCaptions,
    'needsInterpreter': needsInterpreter,
    'easyRead': easyRead,
    'notes': communicationNotes,
  };

  Map<String, dynamic> toFirestoreMap({bool includePassportId = true}) {
    return {
      'role': role,
      if (includePassportId) 'passportId': passportId,
      'personal': {
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'nationality': nationality,
        'preferredLanguage': preferredLanguage,
      },
      'contact': {
        'countryCode': countryCode,
        'mobile': mobile,
        'email': email,
        'country': country,
        'city': city,
        'address': address,
        'postalCode': postalCode,
        'emergency': {
          'name': emergencyName,
          'relation': emergencyRelation,
          'phone': emergencyPhone,
        },
      },
      'accessibility': {
        'profiles': accessibilityProfiles.toList(),
        'assistanceNeeds': assistanceNeeds.toList(),
        'additionalRequirements': additionalRequirements,
        'mobilityAid': mobilityAid,
        'needAccessibleTransport': needAccessibleTransport,
        'needElevator': needElevator,
        'needAccessibleToilet': needAccessibleToilet,
        'needCaregiver': needCaregiver,
        'needServiceAnimal': needServiceAnimal,
        'communication': communicationMap(),
      },
      'healthcare': {
        'doctor': doctor,
        'hospital': hospital,
        'conditions': conditions,
        'allergies': allergies,
        'medications': medications,
        'bloodGroup': bloodGroup,
        'insurance': insurance,
        'emergencyNotes': emergencyNotes,
      },
      'preferences': {
        'largeText': largeText,
        'voiceNavigation': voiceNavigation,
        'darkMode': darkMode,
        'highContrast': highContrast,
        'screenReader': screenReader,
        'hapticFeedback': hapticFeedback,
        'captions': captions,
        'simpleLanguage': simpleLanguage,
        'textSize': textSize,
      },
      'services': {
        'interested': interestedServices.toList(),
        'notifications': {
          'medReminders': medReminders,
          'appointmentReminders': appointmentReminders,
          'nearbyPlaces': nearbyPlaces,
          'benefitUpdates': benefitUpdates,
        },
      },
    };
  }

  static SignupData fromProfile(UserProfile p) {
    final d = SignupData();
    d.role = p.role;
    d.firstName = (p.personal['firstName'] as String?)?.trim() ?? '';
    d.lastName = (p.personal['lastName'] as String?)?.trim() ?? '';
    if (d.firstName.isEmpty && p.displayName.isNotEmpty) {
      final parts = p.displayName.trim().split(RegExp(r'\s+'));
      d.firstName = parts.first;
      if (parts.length > 1) d.lastName = parts.sublist(1).join(' ');
    }
    d.dateOfBirth = p.dateOfBirth == 'Not set' ? '' : p.dateOfBirth;
    d.gender = (p.personal['gender'] as String?)?.trim().isNotEmpty == true
        ? p.personal['gender'] as String
        : d.gender;
    d.nationality =
        (p.personal['nationality'] as String?)?.trim().isNotEmpty == true
        ? p.personal['nationality'] as String
        : d.nationality;
    d.preferredLanguage = p.preferredLanguage;

    d.countryCode =
        (p.contact['countryCode'] as String?)?.trim().isNotEmpty == true
        ? p.contact['countryCode'] as String
        : d.countryCode;
    d.mobile = (p.contact['mobile'] as String?)?.trim() ?? '';
    d.email = p.email;
    d.country = (p.contact['country'] as String?)?.trim().isNotEmpty == true
        ? p.contact['country'] as String
        : d.country;
    d.city = (p.contact['city'] as String?)?.trim().isNotEmpty == true
        ? p.contact['city'] as String
        : d.city;
    d.address = (p.contact['address'] as String?)?.trim() ?? '';
    d.postalCode = (p.contact['postalCode'] as String?)?.trim() ?? '';
    d.emergencyName = (p.emergency['name'] as String?)?.trim() ?? '';
    d.emergencyRelation =
        (p.emergency['relation'] as String?)?.trim().isNotEmpty == true
        ? p.emergency['relation'] as String
        : d.emergencyRelation;
    d.emergencyPhone = (p.emergency['phone'] as String?)?.trim() ?? '';

    d.accessibilityProfiles
      ..clear()
      ..addAll(p.accessibilityProfiles);
    d.assistanceNeeds
      ..clear()
      ..addAll(p.assistanceNeeds);
    d.additionalRequirements =
        (p.accessibility['additionalRequirements'] as String?)?.trim() ?? '';

    d.communicationModes
      ..clear()
      ..addAll(p.communicationModes);
    if (d.communicationModes.isEmpty) {
      d.communicationModes.add('Spoken conversation');
    }
    d.signLanguage = p.signLanguage;
    d.preferredContactMethod = p.preferredContactMethod;
    d.needsCaptions = p.needsCaptions;
    d.needsInterpreter = p.needsInterpreter;
    d.easyRead = p.easyRead;
    d.communicationNotes = p.communicationNotes;

    d.mobilityAid = p.mobilityAid.isNotEmpty ? p.mobilityAid : d.mobilityAid;
    d.needAccessibleTransport =
        p.accessibility['needAccessibleTransport'] == true;
    d.needElevator = p.accessibility['needElevator'] == true;
    d.needAccessibleToilet = p.accessibility['needAccessibleToilet'] == true;
    d.needCaregiver = p.needCaregiver;
    d.needServiceAnimal = p.accessibility['needServiceAnimal'] == true;

    d.doctor = (p.healthcare['doctor'] as String?)?.trim() ?? '';
    d.hospital = (p.healthcare['hospital'] as String?)?.trim() ?? '';
    d.conditions = (p.healthcare['conditions'] as String?)?.trim() ?? '';
    d.allergies = (p.healthcare['allergies'] as String?)?.trim() ?? '';
    d.medications = (p.healthcare['medications'] as String?)?.trim() ?? '';
    d.bloodGroup = p.bloodGroup == '—' ? d.bloodGroup : p.bloodGroup;
    d.insurance =
        (p.healthcare['insurance'] as String?)?.trim().isNotEmpty == true
        ? p.healthcare['insurance'] as String
        : d.insurance;
    d.emergencyNotes =
        (p.healthcare['emergencyNotes'] as String?)?.trim() ?? '';

    bool flag(String k, bool fallback) {
      final v = p.preferences[k];
      if (v is bool) return v;
      return fallback;
    }

    d.largeText = flag('largeText', d.largeText);
    d.voiceNavigation = flag('voiceNavigation', d.voiceNavigation);
    d.darkMode = flag('darkMode', d.darkMode);
    d.highContrast = flag('highContrast', d.highContrast);
    d.screenReader = flag('screenReader', d.screenReader);
    d.hapticFeedback = flag('hapticFeedback', d.hapticFeedback);
    d.captions = flag('captions', d.captions);
    d.simpleLanguage = flag('simpleLanguage', d.simpleLanguage);
    final ts = p.preferences['textSize'];
    if (ts is num) d.textSize = ts.toDouble();
    return d;
  }
}
