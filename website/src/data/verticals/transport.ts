import { Bus, TrainFront, Car, Ship, Plane, Users, Compass, MapPin } from 'lucide-react';
import type { VerticalPageContent } from '@/lib/types';

export const transport: VerticalPageContent = {
  eyebrow: 'Accessible Transport',
  title: 'Mobility for a',
  titleAccent: 'More Inclusive World',
  subtitle:
    'Find, book and use accessible transportation options in your city and while traveling. Because everyone deserves to go everywhere.',
  heroImage: 'https://picsum.photos/seed/transport/800/600',
  handwrittenCaption: 'More Places\nBrighter Lives',
  searchPlaceholder: 'Where do you want to go?',
  trustBadges: ['Verified Providers', 'Accessible Vehicles', 'Real-time Availability', 'Multiple Payment Options', 'Travel for Everyone'],
  quickLinks: [
    { icon: Compass, label: 'Find Transport' },
    { icon: MapPin, label: 'Plan a Trip' },
    { icon: Bus, label: 'Transport Guide' },
  ],
  tabs: ['All Options', 'Accessible Buses', 'Accessible Trains', 'Accessible Taxis', 'Paratransit', 'Airports', 'Ferries', 'Travel Assistance'],
  categoriesHeading: 'Transport Options',
  categoriesSubheading: 'Choose the best option for your needs.',
  categories: [
    { icon: Bus, label: 'Accessible Buses', description: 'Low-floor buses with ramps and priority seating', color: 'blue' },
    { icon: TrainFront, label: 'Accessible Trains', description: 'Step-free travel and assistance', color: 'emerald' },
    { icon: Car, label: 'Accessible Taxis', description: 'Book wheelchair accessible taxis', color: 'amber' },
    { icon: Users, label: 'Paratransit Services', description: 'On-demand transport for persons with disabilities', color: 'violet' },
    { icon: Plane, label: 'Accessible Airports', description: 'Airport assistance and accessible transfers', color: 'rose' },
    { icon: Ship, label: 'Accessible Ferries', description: 'Travel by water with confidence', color: 'sky' },
  ],
  featuredHeading: 'Featured Routes',
  featuredSubheading: 'Popular accessible routes in your area and beyond.',
  featured: [
    { title: 'Islamabad → Abbottabad', meta: 'Accessible Bus', description: '2h 30m · Multiple daily trips', image: 'https://picsum.photos/seed/tr-1/480/300', tag: 'Accessible', cta: 'View Route' },
    { title: 'Lahore → Islamabad', meta: 'Accessible Train', description: '4h 20m · Step-free access', image: 'https://picsum.photos/seed/tr-2/480/300', tag: 'Accessible', cta: 'View Route' },
    { title: 'Islamabad Airport', meta: 'Airport Assistance', description: 'Wheelchair support · Priority boarding', image: 'https://picsum.photos/seed/tr-3/480/300', tag: 'Accessible', cta: 'View Route' },
  ],
  howItWorksHeading: 'How It Works',
  howItWorks: [
    { step: 1, title: 'Search', description: 'Enter your location and destination.' },
    { step: 2, title: 'Choose', description: 'Compare accessible options.' },
    { step: 3, title: 'Book', description: 'Confirm your trip online or by phone.' },
    { step: 4, title: 'Travel', description: 'Enjoy a safe and accessible journey.' },
  ],
  testimonialsHeading: 'Travel Stories',
  testimonials: [
    { quote: 'Accessible transport has made it possible for me to attend work and social events independently.', name: 'Usman R.', location: 'Rawalpindi' },
    { quote: 'The paratransit service is reliable and the drivers are always helpful.', name: 'Sara K.', location: 'Islamabad' },
    { quote: 'Booking an accessible taxi used to be stressful. Now it takes minutes.', name: 'Imran A.', location: 'Lahore' },
  ],
  ctaHeading: 'Accessible Journeys. Stronger Communities.',
  ctaSubheading: 'Plan your next trip with confidence using verified accessible transport.',
  ctaLabel: 'Plan Your Trip',
  footerTagline: 'Mobility for people. Opportunity for all.',
};
