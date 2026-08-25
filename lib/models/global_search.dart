import 'benefit_scheme.dart';
import 'community.dart';
import 'education_program.dart';
import 'place.dart';
import 'service_provider.dart';
import 'transport_option.dart';
import 'travel_destination.dart';

enum GlobalSearchKind {
  all,
  places,
  doctors,
  therapists,
  caregivers,
  assistants,
  hotels,
  restaurants,
  schools,
  courses,
  benefits,
  transportation,
  tourism,
  community;

  String get label => switch (this) {
    all => 'All',
    places => 'Places',
    doctors => 'Doctors',
    therapists => 'Therapists',
    caregivers => 'Caregivers',
    assistants => 'Assistants',
    hotels => 'Hotels',
    restaurants => 'Restaurants',
    schools => 'Schools',
    courses => 'Courses',
    benefits => 'Benefits',
    transportation => 'Transport',
    tourism => 'Tourism',
    community => 'Community',
  };
}

class GlobalSearchCatalog {
  const GlobalSearchCatalog({
    this.places = const [],
    this.providers = const [],
    this.destinations = const [],
    this.programs = const [],
    this.schemes = const [],
    this.offices = const [],
    this.transport = const [],
    this.posts = const [],
    this.groups = const [],
    this.events = const [],
  });

  final List<AccessiblePlace> places;
  final List<ServiceProvider> providers;
  final List<TravelDestination> destinations;
  final List<EducationProgram> programs;
  final List<BenefitScheme> schemes;
  final List<GovernmentOffice> offices;
  final List<TransportOption> transport;
  final List<CommunityPost> posts;
  final List<CommunityGroup> groups;
  final List<CommunityEvent> events;
}

class GlobalSearchHit {
  const GlobalSearchHit({
    required this.key,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.rank,
    required this.payload,
    this.imageUrl = '',
  });

  final String key;
  final GlobalSearchKind kind;
  final String title;
  final String subtitle;
  final int rank;
  final Object payload;
  final String imageUrl;
}
