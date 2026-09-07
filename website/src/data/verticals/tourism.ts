import { Plane, Building, Compass, Users, BookOpen, MapPin } from 'lucide-react';
import type { VerticalPageContent } from '@/lib/types';

export const tourism: VerticalPageContent = {
  eyebrow: 'Accessible Tourism',
  title: 'Explore the World',
  titleAccent: 'Without Limits',
  subtitle:
    'Discover accessible travel destinations, plan your trips, find verified accessible facilities and experience a more inclusive world.',
  heroImage: 'https://picsum.photos/seed/tourism/800/600',
  handwrittenCaption: 'Travel Belongs\nto Everyone',
  searchPlaceholder: 'Where do you want to go?',
  trustBadges: ['Popular Destinations', 'Accessible Stays', 'Guided Tours', 'Real Stories'],
  quickLinks: [
    { icon: Plane, label: 'Accessible Destinations' },
    { icon: Building, label: 'Verified Facilities' },
    { icon: MapPin, label: 'Plan Your Trip' },
    { icon: Users, label: 'Travel Community' },
    { icon: BookOpen, label: 'Guides & Resources' },
  ],
  tabs: ['Accessible Destinations', 'Accessible Stays', 'Accessible Transport', 'Guided Tours', 'Travel Tips', 'Visa & Travel Info', 'Real Stories'],
  categoriesHeading: 'Plan Your Accessible Journey',
  categoriesSubheading: 'Everything you need to travel with confidence.',
  categories: [
    { icon: MapPin, label: 'Accessible Destinations', description: 'Explore verified accessible places worldwide', color: 'emerald' },
    { icon: Building, label: 'Accessible Stays', description: 'Find accessible hotels, resorts and rentals', color: 'rose' },
    { icon: Plane, label: 'Accessible Transport', description: 'Information on flights, trains, buses and local transport', color: 'violet' },
    { icon: Compass, label: 'Guided Tours', description: 'Accessible tours and experiences', color: 'sky' },
    { icon: BookOpen, label: 'Travel Tips', description: 'Practical tips for hassle-free travel', color: 'amber' },
    { icon: Users, label: 'Travel Community', description: 'Connect with fellow travelers', color: 'blue' },
  ],
  featuredHeading: 'Popular Accessible Destinations',
  featuredSubheading: 'Explore beautiful destinations working towards a more inclusive tourism experience.',
  featured: [
    { title: 'Istanbul, Türkiye', meta: 'Accessible', description: 'History, culture and inclusive experiences', image: 'https://picsum.photos/seed/tour-1/480/300', tag: 'Accessible', cta: 'View Destination' },
    { title: 'Barcelona, Spain', meta: 'Very Accessible', description: 'Vibrant city with inclusive infrastructure', image: 'https://picsum.photos/seed/tour-2/480/300', tag: 'Very Accessible', cta: 'View Destination' },
    { title: 'Dubai, UAE', meta: 'Accessible', description: 'Modern, accessible and welcoming', image: 'https://picsum.photos/seed/tour-3/480/300', tag: 'Accessible', cta: 'View Destination' },
    { title: 'London, United Kingdom', meta: 'Accessible', description: 'Iconic landmarks for everyone', image: 'https://picsum.photos/seed/tour-4/480/300', tag: 'Accessible', cta: 'View Destination' },
  ],
  howItWorksHeading: 'Trip Planner',
  howItWorks: [
    { step: 1, title: 'Choose Destination', description: 'Explore accessible places.' },
    { step: 2, title: 'Plan Dates', description: 'Find the best time to travel.' },
    { step: 3, title: 'Find Accessible Options', description: 'Hotels, transport and activities.' },
    { step: 4, title: 'Build Your Itinerary', description: 'Save and share your plan.' },
  ],
  testimonialsHeading: 'Real Stories',
  testimonials: [
    { quote: 'Traveling opened my world. Ability Link made it possible.', name: 'Ali R.', location: 'Traveler' },
    { quote: 'I finally planned a wheelchair-accessible trip to Istanbul without stress.', name: 'Ayesha K.', location: 'Traveler & Advocate' },
    { quote: 'The accessible hotel guides saved me hours of research before my trip.', name: 'Zainab F.', location: 'Traveler' },
  ],
  ctaHeading: 'Join the Travel Community',
  ctaSubheading: 'Connect with fellow travelers, share your experiences and get real recommendations.',
  ctaLabel: 'Join Now',
  footerTagline: 'More accessible journeys. A brighter tomorrow.',
};
