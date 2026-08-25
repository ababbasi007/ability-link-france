import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/care_appointment.dart';
import '../models/service_provider.dart';
import 'billing_service.dart';
import 'seed_write_guard.dart';

class ProvidersService {
  ProvidersService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _providers =>
      _db.collection('providers');

  Stream<List<ServiceProvider>> watchProviders({int limit = 250}) {
    return _providers
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) {
            final remote = snap.docs
                .map(ServiceProvider.fromDoc)
                .where((p) => !p.hidden)
                .toList();
            if (remote.isNotEmpty) return remote;
            return seedProviders.where((p) => !p.hidden).toList();
          },
        );
  }

  Future<ServiceProvider?> getProvider(String id) async {
    final doc = await _providers.doc(id).get();
    if (!doc.exists) return null;
    return ServiceProvider.fromDoc(doc);
  }

  List<ServiceProvider> filter(
    List<ServiceProvider> all, {
    String query = '',
    String category = 'All',
    bool verifiedOnly = false,
    bool availableNowOnly = false,
    String specialty = '',
    String assistanceType = '',
    String city = '',
    int? maxPrice,
  }) {
    var list = all.where((p) {
      if (!p.matchesQuery(query)) return false;
      if (!p.matchesCategory(category)) return false;
      if (verifiedOnly && !p.verified) return false;
      if (availableNowOnly && !p.availableNow) return false;
      if (specialty.isNotEmpty &&
          !p.specialty.toLowerCase().contains(specialty.toLowerCase())) {
        return false;
      }
      if (assistanceType.isNotEmpty &&
          !p.matchesAssistanceType(assistanceType)) {
        return false;
      }
      if (city.isNotEmpty &&
          !p.city.toLowerCase().contains(city.trim().toLowerCase())) {
        return false;
      }
      if (maxPrice != null && p.priceFrom > maxPrice) return false;
      return true;
    }).toList();
    list.sort((a, b) {
      if (a.verified != b.verified) return a.verified ? -1 : 1;
      return b.rating.compareTo(a.rating);
    });
    return list;
  }

  Future<String> submitEnquiry(ProviderEnquiry enquiry) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to send an enquiry');
    }
    final ref = _db.collection('enquiries').doc();
    await ref.set({
      'id': ref.id,
      'uid': user.uid,
      'userEmail': user.email ?? '',
      'userName': user.displayName ?? '',
      'providerId': enquiry.providerId,
      'providerName': enquiry.providerName,
      'service': enquiry.service,
      'message': enquiry.message,
      'preferredSlot': enquiry.preferredSlot,
      'contactPhone': enquiry.contactPhone,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Mirror under user for their history.
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('enquiries')
        .doc(ref.id)
        .set({
          'enquiryId': ref.id,
          'providerId': enquiry.providerId,
          'providerName': enquiry.providerName,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
    final billed = await getProvider(enquiry.providerId);
    if (billed != null && billed.ownerUid.isNotEmpty) {
      await BillingService(db: _db, auth: _auth).recordLeadFee(
        ownerUid: billed.ownerUid,
        providerName: enquiry.providerName,
        enquiryId: ref.id,
      );
    }
    return ref.id;
  }

  Future<int> ensureSeeded() {
    return SeedWriteGuard.runOnce('providers', _auth, () async {
      const catalog = 'providers';
      var n = 0;
      for (final p in seedProviders) {
        final ref = _providers.doc(p.id);
        final snap = await ref.get();
        if (!snap.exists) {
          try {
            await ref.set({
              ...p.toMap(),
              'seeded': true,
              'createdAt': FieldValue.serverTimestamp(),
            });
            n++;
          } on FirebaseException catch (e) {
            if (SeedWriteGuard.isPermissionDenied(e)) {
              await SeedWriteGuard.block(catalog);
              break;
            }
            rethrow;
          }
        }
      }
      return n;
    });
  }

  Stream<ServiceProvider?> watchMyOrg() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _providers.where('ownerUid', isEqualTo: uid).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      return ServiceProvider.fromDoc(snap.docs.first);
    });
  }

  Future<String> createOrg({
    required String name,
    required String category,
    required String specialty,
    required String city,
    required String bio,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to register an organisation');
    final existing = await _providers
        .where('ownerUid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;
    final ref = _providers.doc();
    await ref.set({
      'name': name.trim(),
      'title': 'Org',
      'category': category,
      'specialty': specialty.trim(),
      'bio': bio.trim(),
      'rating': 0,
      'reviewCount': 0,
      'priceFrom': 0,
      'currency': '\$',
      'languages': ['English'],
      'services': ['Consultation'],
      'accessibilityTags': <String>[],
      'city': city.trim(),
      'photoUrl': '',
      'verified': false,
      'availableNow': true,
      'yearsExperience': 0,
      'ownerUid': user.uid,
      'checklist': {for (final k in kAccessibilityChecklist.keys) k: false},
      'evidence': <Map<String, String>>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> saveChecklist(String id, Map<String, bool> checklist) async {
    await _providers.doc(id).update({'checklist': checklist});
  }

  Future<void> addEvidence(
    String id, {
    required String title,
    required String url,
  }) async {
    await _providers.doc(id).update({
      'evidence': FieldValue.arrayUnion([
        {'title': title.trim(), 'url': url.trim()},
      ]),
    });
  }

  Future<void> setAvailable(String id, bool available) async {
    await _providers.doc(id).update({'availableNow': available});
  }

  Stream<List<EnquiryLead>> watchLeads(String providerId) {
    return _db
        .collection('enquiries')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(EnquiryLead.fromDoc).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> setLeadStatus(String enquiryId, String status) async {
    await _db.collection('enquiries').doc(enquiryId).update({'status': status});
  }

  Stream<List<CareAppointment>> watchProviderAppointments(String providerId) {
    return _db
        .collection('appointments')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(CareAppointment.fromDoc).toList();
          list.sort((a, b) => a.startAt.compareTo(b.startAt));
          return list;
        });
  }

  Future<void> setAppointmentStatus(String appointmentId, String status) async {
    final ref = _db.collection('appointments').doc(appointmentId);
    await ref.update({'status': status});
    if (status != 'completed') return;
    final snap = await ref.get();
    final providerId = (snap.data()?['providerId'] as String?) ?? '';
    final providerName = (snap.data()?['providerName'] as String?) ?? '';
    if (providerId.isEmpty) return;
    final provider = await getProvider(providerId);
    if (provider == null || provider.ownerUid.isEmpty) return;
    await BillingService(db: _db, auth: _auth).recordSessionCommission(
      ownerUid: provider.ownerUid,
      providerName: providerName.isEmpty ? provider.name : providerName,
      appointmentId: appointmentId,
    );
  }
}

final seedProviders = <ServiceProvider>[
  ServiceProvider(
    id: 'dr-sara-ahmed',
    name: 'Dr. Sara Ahmed',
    title: 'MD',
    category: 'healthcare',
    specialty: 'General Physician',
    bio:
        'Accessible telehealth consultations with clear captions and plain-language summaries. Experience supporting wheelchair users and chronic conditions.',
    rating: 4.9,
    reviewCount: 214,
    priceFrom: 35,
    currency: '\$',
    languages: ['English', 'Urdu', 'Arabic'],
    services: ['Video consult', 'Follow-up plan', 'Prescription review'],
    accessibilityTags: ['wheelchair', 'captions', 'plain-language'],
    city: 'New York, NY',
    photoUrl:
        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=400&fit=crop',
    verified: true,
    availableNow: true,
    yearsExperience: 12,
  ),
  ServiceProvider(
    id: 'pt-james-okonkwo',
    name: 'James Okonkwo',
    title: 'PT',
    category: 'rehab',
    specialty: 'Physiotherapist',
    bio:
        'Tele-rehab specialist for mobility, post-surgery recovery, and home exercise programs adapted to assistive devices.',
    rating: 4.8,
    reviewCount: 156,
    priceFrom: 40,
    currency: '\$',
    languages: ['English', 'French'],
    services: ['Tele-rehab session', 'Exercise plan', 'Progress review'],
    accessibilityTags: ['wheelchair', 'mobility', 'caregiver-friendly'],
    city: 'Brooklyn, NY',
    photoUrl:
        'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400&h=400&fit=crop',
    verified: true,
    availableNow: false,
    yearsExperience: 9,
  ),
  ServiceProvider(
    id: 'dr-lena-cho',
    name: 'Dr. Lena Cho',
    title: 'MD',
    category: 'healthcare',
    specialty: 'Neurologist',
    bio:
        'Neurology consults with sensory-friendly pacing, written visit notes, and caregiver participation options.',
    rating: 4.7,
    reviewCount: 98,
    priceFrom: 55,
    currency: '\$',
    languages: ['English', 'Korean'],
    services: ['Specialist consult', 'Care plan', 'Second opinion'],
    accessibilityTags: ['cognitive', 'caregiver-friendly', 'captions'],
    city: 'Queens, NY',
    photoUrl:
        'https://images.unsplash.com/photo-1594824476967-48c8b964273f?w=400&h=400&fit=crop',
    verified: true,
    availableNow: true,
    yearsExperience: 15,
  ),
  ServiceProvider(
    id: 'ot-maya-singh',
    name: 'Maya Singh',
    title: 'OT',
    category: 'rehab',
    specialty: 'Occupational Therapist',
    bio:
        'Helps with daily living adaptations, home accessibility tips, and workplace accommodations.',
    rating: 4.8,
    reviewCount: 121,
    priceFrom: 38,
    currency: '\$',
    languages: ['English', 'Hindi'],
    services: ['OT assessment', 'Home adaptations', 'Workplace advice'],
    accessibilityTags: ['visual', 'cognitive', 'mobility'],
    city: 'Jersey City, NJ',
    photoUrl:
        'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&h=400&fit=crop',
    verified: false,
    availableNow: true,
    yearsExperience: 7,
  ),
  ServiceProvider(
    id: 'slp-nora-elias',
    name: 'Nora Elias',
    title: 'CCC-SLP',
    category: 'rehab',
    specialty: 'Speech-Language Pathologist',
    bio:
        'Tele-rehab speech, swallowing, and AAC coaching with captions and extra processing time.',
    rating: 4.9,
    reviewCount: 88,
    priceFrom: 42,
    currency: '\$',
    languages: ['English', 'Arabic'],
    services: ['Speech therapy', 'Swallowing therapy', 'AAC coaching'],
    accessibilityTags: ['hearing', 'cognitive', 'captions'],
    city: 'Manhattan, NY',
    photoUrl:
        'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=400&h=400&fit=crop',
    verified: true,
    availableNow: true,
    yearsExperience: 10,
  ),
  ServiceProvider(
    id: 'dr-amir-hassan',
    name: 'Dr. Amir Hassan',
    title: 'MD',
    category: 'healthcare',
    specialty: 'Cardiologist',
    bio:
        'Heart consults with captioned visits, plain-language reports, and wheelchair-accessible clinic options.',
    rating: 4.8,
    reviewCount: 132,
    priceFrom: 60,
    currency: '\$',
    languages: ['English', 'Arabic'],
    services: ['Video consult', 'Audio consult', 'ECG review'],
    accessibilityTags: ['wheelchair', 'captions', 'plain-language'],
    city: 'Manhattan, NY',
    photoUrl:
        'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&h=400&fit=crop',
    verified: true,
    availableNow: true,
    yearsExperience: 14,
  ),
  ServiceProvider(
    id: 'dr-nina-park',
    name: 'Dr. Nina Park',
    title: 'MD',
    category: 'healthcare',
    specialty: 'Dermatologist',
    bio:
        'Skin consults with photo review, chat follow-ups, and sensory-friendly pacing.',
    rating: 4.6,
    reviewCount: 76,
    priceFrom: 45,
    currency: '\$',
    languages: ['English', 'Korean'],
    services: ['Chat consult', 'Photo review', 'Follow-up plan'],
    accessibilityTags: ['sensory', 'captions'],
    city: 'Queens, NY',
    photoUrl:
        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=400&fit=crop',
    verified: true,
    availableNow: false,
    yearsExperience: 8,
  ),
  ServiceProvider(
    id: 'dr-eli-brooks',
    name: 'Dr. Eli Brooks',
    title: 'MD',
    category: 'healthcare',
    specialty: 'Pediatrician',
    bio:
        'Family telehealth with caregiver participation, extra time, and written visit notes.',
    rating: 4.9,
    reviewCount: 201,
    priceFrom: 40,
    currency: '\$',
    languages: ['English', 'Spanish'],
    services: ['Video consult', 'Chat consult', 'Well-child plan'],
    accessibilityTags: ['caregiver-friendly', 'plain-language', 'captions'],
    city: 'Brooklyn, NY',
    photoUrl:
        'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400&h=400&fit=crop',
    verified: true,
    availableNow: true,
    yearsExperience: 11,
  ),
  ServiceProvider(
    id: 'dr-sofia-ramos',
    name: 'Dr. Sofia Ramos',
    title: 'MD',
    category: 'healthcare',
    specialty: 'Psychiatrist',
    bio:
        'Mental health consults with optional audio-only visits, captions, and written summaries.',
    rating: 4.7,
    reviewCount: 118,
    priceFrom: 70,
    currency: '\$',
    languages: ['English', 'Spanish'],
    services: ['Audio consult', 'Video consult', 'Medication review'],
    accessibilityTags: ['cognitive', 'captions', 'plain-language'],
    city: 'Jersey City, NJ',
    photoUrl:
        'https://images.unsplash.com/photo-1594824476967-48c8b964273f?w=400&h=400&fit=crop',
    verified: true,
    availableNow: true,
    yearsExperience: 13,
  ),
  ServiceProvider(
    id: 'edu-omar-hassan',
    name: 'Omar Hassan',
    title: 'M.Ed',
    category: 'education',
    specialty: 'Inclusive Education Advisor',
    bio:
        'Guides families on accessible schools, IEPs, and assistive learning tools.',
    rating: 4.6,
    reviewCount: 67,
    priceFrom: 30,
    currency: '\$',
    languages: ['English', 'Arabic'],
    services: ['School matching', 'IEP prep', 'Assistive tech tips'],
    accessibilityTags: ['cognitive', 'hearing', 'visual'],
    city: 'Newark, NJ',
    photoUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
    verified: true,
    availableNow: false,
    yearsExperience: 11,
  ),
  ServiceProvider(
    id: 'care-priya-nair',
    name: 'Priya Nair',
    title: 'RN',
    category: 'assistance',
    specialty: 'Care Coordinator',
    bio:
        'Personal assistance and care coordination — schedules, medication prompts, and family briefings.',
    rating: 4.9,
    reviewCount: 143,
    priceFrom: 28,
    currency: '\$',
    languages: ['English', 'Malayalam', 'Hindi'],
    services: [
      'Care plan',
      'Family briefing',
      'Remote check-in',
      'Personal assistance',
    ],
    accessibilityTags: ['caregiver-friendly', 'plain-language'],
    city: 'New York, NY',
        photoUrl:
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&h=400&fit=crop',
    verified: true,
    availableNow: true,
    yearsExperience: 10,
    checklist: {
      'staffTrained': true,
      'plainLanguageMaterials': true,
      'captionsOnVideo': true,
      'serviceAnimalWelcome': true,
    },
    availabilitySlots: [
      'Mon–Fri 8am–2pm',
      'Sat 9am–12pm',
      'Remote check-in evenings',
    ],
    assistanceType: 'personal_assistant',
    skills: ['Scheduling', 'Med prompts', 'Family liaison', 'ADL support'],
  ),
  ServiceProvider(
    id: 'assist-lena-park',
    name: 'Lena Park',
    title: 'Guide',
    category: 'assistance',
    specialty: 'Visual Impairment Support',
    bio:
        'Sighted guide for errands, transit, and appointments. Orientation & mobility aware.',
    rating: 4.8,
    reviewCount: 88,
    priceFrom: 30,
    currency: '\$',
    languages: ['English', 'Korean'],
    services: ['Sighted guide', 'Transit escort', 'Shopping support'],
    accessibilityTags: ['visual', 'plain-language'],
    city: 'Queens, NY',
    photoUrl:
        'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&h=400&fit=crop',
    verified: true,
    availableNow: true,
    yearsExperience: 6,
    checklist: {
      'staffTrained': true,
      'plainLanguageMaterials': true,
      'serviceAnimalWelcome': true,
    },
    availabilitySlots: ['Mon–Fri 10am–6pm', 'Sat mornings'],
    assistanceType: 'visual_impairment',
    skills: ['Sighted guide', 'Transit', 'Audio description', 'O&M basics'],
  ),
  ServiceProvider(
    id: 'assist-noah-wright',
    name: 'Noah Wright',
    title: 'Scribe',
    category: 'assistance',
    specialty: 'Writer / Scribe',
    bio:
        'Classroom and exam scribe, form-filling, and meeting note-taking with plain-language summaries.',
    rating: 4.7,
    reviewCount: 71,
    priceFrom: 25,
    currency: '\$',
    languages: ['English'],
    services: ['Exam scribe', 'Form filling', 'Meeting notes'],
    accessibilityTags: ['cognitive', 'plain-language', 'visual'],
    city: 'Newark, NJ',
    photoUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop',
    verified: true,
    availableNow: false,
    yearsExperience: 4,
    checklist: {'staffTrained': true, 'plainLanguageMaterials': true},
    availabilitySlots: ['Weekdays 9am–3pm'],
    assistanceType: 'writer_scribe',
    skills: ['Scribing', 'Forms', 'Note-taking', 'Keyboarding'],
  ),
  ServiceProvider(
    id: 'assist-sofia-reyes',
    name: 'Sofia Reyes',
    title: 'CI',
    category: 'assistance',
    specialty: 'Sign Language Interpreter',
    bio:
        'ASL / Spanish interpreting for clinics, schools, and community appointments. Remote VRI available.',
    rating: 4.9,
    reviewCount: 120,
    priceFrom: 55,
    currency: '\$',
    languages: ['ASL', 'English', 'Spanish'],
    services: ['ASL interpreting', 'VRI', 'Community appointments'],
    accessibilityTags: ['hearing', 'captions'],
    city: 'Manhattan, NY',
    photoUrl:
        'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&h=400&fit=crop',
    verified: true,
    availableNow: true,
    yearsExperience: 9,
    checklist: {'staffTrained': true, 'captionsOnVideo': true},
    availabilitySlots: ['Mon–Sat by request', 'Same-day VRI'],
    assistanceType: 'sign_language',
    skills: ['ASL', 'VRI', 'Medical interpreting', 'Education settings'],
  ),
  ServiceProvider(
    id: 'care-marcus-lee',
    name: 'Marcus Lee',
    title: 'CNA',
    category: 'assistance',
    specialty: 'Mobility Assistant',
    bio:
        'Transfers, wheelchair navigation, and community mobility support. Hospital discharge friendly.',
    rating: 4.8,
    reviewCount: 97,
    priceFrom: 32,
    currency: '\$',
    languages: ['English', 'Spanish'],
    services: ['Transfers', 'Wheelchair escort', 'Errands'],
    accessibilityTags: ['mobility', 'caregiver-friendly'],
    city: 'Brooklyn, NY',
    photoUrl:
        'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400&h=400&fit=crop',
    verified: true,
    availableNow: true,
    yearsExperience: 7,
    checklist: {
      'staffTrained': true,
      'stepFreeEntrance': true,
      'serviceAnimalWelcome': true,
    },
    availabilitySlots: ['Tue–Thu 10am–6pm', 'Sun mornings'],
    assistanceType: 'mobility',
    skills: ['Transfers', 'Wheelchair', 'Safe lifting', 'Community access'],
  ),
  ServiceProvider(
    id: 'assist-jordan-kim',
    name: 'Jordan Kim',
    title: 'CMA',
    category: 'assistance',
    specialty: 'Healthcare Assistant',
    bio:
        'Clinic and hospital companion — wait support, meds prompts, and plain-language visit summaries.',
    rating: 4.8,
    reviewCount: 82,
    priceFrom: 35,
    currency: '\$',
    languages: ['English', 'Mandarin'],
    services: ['Hospital companion', 'Clinic wait support', 'Meds prompts'],
    accessibilityTags: ['plain-language', 'mobility'],
    city: 'Jersey City, NJ',
    photoUrl:
        'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&h=400&fit=crop',
    verified: true,
    availableNow: true,
    yearsExperience: 8,
    checklist: {
      'staffTrained': true,
      'plainLanguageMaterials': true,
      'captionsOnVideo': true,
    },
    availabilitySlots: ['Mon–Fri 8am–5pm'],
    assistanceType: 'healthcare_assistant',
    skills: ['Clinic liaison', 'Med prompts', 'Patient advocacy'],
  ),
  ServiceProvider(
    id: 'assist-maya-chen',
    name: 'Maya Chen',
    title: 'Ed Aide',
    category: 'assistance',
    specialty: 'Education Support',
    bio:
        'Classroom aide and IEP meeting support. Assistive tech tips for reading and writing.',
    rating: 4.7,
    reviewCount: 59,
    priceFrom: 27,
    currency: '\$',
    languages: ['English', 'Mandarin'],
    services: ['Classroom aide', 'IEP support', 'Study sessions'],
    accessibilityTags: ['cognitive', 'visual', 'hearing'],
    city: 'Newark, NJ',
    photoUrl:
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop',
    verified: true,
    availableNow: false,
    yearsExperience: 5,
    checklist: {'staffTrained': true, 'plainLanguageMaterials': true},
    availabilitySlots: ['School days 8am–4pm'],
    assistanceType: 'education_support',
    skills: ['IEP', 'Classroom support', 'Assistive tech', 'Note support'],
  ),
  ServiceProvider(
    id: 'assist-omar-diallo',
    name: 'Omar Diallo',
    title: 'Travel',
    category: 'assistance',
    specialty: 'Travel Assistant',
    bio:
        'Airport, train, and intercity travel companion. Step-free routing and luggage help.',
    rating: 4.6,
    reviewCount: 54,
    priceFrom: 40,
    currency: '\$',
    languages: ['English', 'French', 'Wolof'],
    services: ['Airport escort', 'Train transfer', 'Luggage help'],
    accessibilityTags: ['mobility', 'cognitive'],
    city: 'Newark, NJ',
    photoUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop',
    verified: true,
    availableNow: true,
    yearsExperience: 6,
    checklist: {'staffTrained': true, 'stepFreeEntrance': true},
    availabilitySlots: ['Travel days by request', 'Early mornings'],
    assistanceType: 'travel_assistant',
    skills: ['Airports', 'Transit', 'Step-free routing', 'Luggage'],
  ),
  ServiceProvider(
    id: 'assist-helen-brooks',
    name: 'Helen Brooks',
    title: 'Care',
    category: 'assistance',
    specialty: 'Elderly Care',
    bio:
        'Companion care for older adults — meals, gentle walks, and appointment support at home.',
    rating: 4.9,
    reviewCount: 110,
    priceFrom: 29,
    currency: '\$',
    languages: ['English'],
    services: ['Companion care', 'Meals', 'Appointment escort'],
    accessibilityTags: ['mobility', 'hearing', 'plain-language'],
    city: 'Manhattan, NY',
    photoUrl:
        'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=400&h=400&fit=crop',
    verified: true,
    availableNow: true,
    yearsExperience: 12,
    checklist: {
      'staffTrained': true,
      'plainLanguageMaterials': true,
      'serviceAnimalWelcome': true,
    },
    availabilitySlots: ['Mon–Fri 9am–5pm', 'Evenings by request'],
    assistanceType: 'elderly_care',
    skills: ['Companion care', 'Meals', 'Fall awareness', 'Family updates'],
  ),
  ServiceProvider(
    id: 'care-amina-hassan',
    name: 'Amina Hassan',
    title: 'PA',
    category: 'assistance',
    specialty: 'Home Support',
    bio:
        'Quiet, sensory-aware home support for neurodivergent adults and older adults living independently.',
    rating: 4.7,
    reviewCount: 64,
    priceFrom: 26,
    currency: '\$',
    languages: ['English', 'French', 'Arabic'],
    services: ['Home support', 'Medication prompts', 'Community outings'],
    accessibilityTags: ['sensory', 'cognitive', 'plain-language'],
    city: 'Jersey City, NJ',
    photoUrl:
        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=400&fit=crop',
    verified: true,
    availableNow: false,
    yearsExperience: 5,
    checklist: {
      'staffTrained': true,
      'plainLanguageMaterials': true,
      'sensoryFriendlyHours': true,
    },
    availabilitySlots: ['Mon–Wed 1pm–7pm', 'Fri afternoons'],
    assistanceType: 'home_support',
    skills: ['Home routines', 'Sensory-aware', 'Meal prep', 'Light chores'],
  ),
];
