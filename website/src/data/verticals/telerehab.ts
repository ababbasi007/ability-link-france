import { Video, ClipboardList, BarChart3, Users, Accessibility, MessageSquare, Brain, Cpu, PersonStanding, Dumbbell } from 'lucide-react';
import type { VerticalPageContent } from '@/lib/types';

export const telerehab: VerticalPageContent = {
  eyebrow: 'Tele Rehab',
  title: 'Recover. Move Forward.',
  titleAccent: 'From Anywhere.',
  subtitle:
    'Access professional rehabilitation support through secure video sessions. Personalised care for a stronger, more independent you.',
  heroImage: 'https://picsum.photos/seed/telerehab/800/600',
  handwrittenCaption: 'Same Support\nMore Possibilities',
  searchPlaceholder: 'Search therapists, conditions or exercise programs',
  trustBadges: ['Licensed Professionals', 'Secure & Private', 'Accessible for All', 'Care from Anywhere'],
  quickLinks: [
    { icon: Video, label: 'Video Consultations' },
    { icon: ClipboardList, label: 'Personalised Exercise Plans' },
    { icon: BarChart3, label: 'Progress Tracking' },
    { icon: Accessibility, label: 'Post-Surgical Recovery' },
    { icon: Users, label: 'Follow-up Support' },
  ],
  tabs: ['Physiotherapy', 'Occupational Therapy', 'Speech Therapy', 'Neuro Rehabilitation', 'Prosthetics Training', 'Mobility Training', 'Post-Surgical Recovery'],
  categoriesHeading: 'Our Rehabilitation Services',
  categoriesSubheading: 'Choose the type of support you need.',
  categories: [
    { icon: PersonStanding, label: 'Physiotherapy', description: 'Improve movement, strength and mobility', color: 'blue' },
    { icon: Dumbbell, label: 'Occupational Therapy', description: 'Build daily living skills and independence', color: 'emerald' },
    { icon: MessageSquare, label: 'Speech Therapy', description: 'Support communication and speech development', color: 'rose' },
    { icon: Brain, label: 'Neuro Rehabilitation', description: 'Care for stroke, brain injury and neurological conditions', color: 'violet' },
    { icon: Cpu, label: 'Prosthetics Training', description: 'Learn to use and adapt to prosthetic devices', color: 'amber' },
    { icon: Accessibility, label: 'Mobility Training', description: 'Wheelchair skills and mobility support', color: 'sky' },
  ],
  featuredHeading: 'Featured Therapists',
  featuredSubheading: 'Our licensed and experienced rehabilitation professionals.',
  featured: [
    { title: 'Dr. Sarah Khan', meta: 'Physiotherapist', description: '5+ years experience', image: 'https://picsum.photos/seed/tre-1/480/300', rating: '4.9 (120 reviews)', cta: 'View Profile' },
    { title: 'Dr. Ahmed Raza', meta: 'Occupational Therapist', description: '7+ years experience', image: 'https://picsum.photos/seed/tre-2/480/300', rating: '4.8 (98 reviews)', cta: 'View Profile' },
    { title: 'Ms. Ayesha Malik', meta: 'Speech Therapist', description: '6+ years experience', image: 'https://picsum.photos/seed/tre-3/480/300', rating: '4.9 (76 reviews)', cta: 'View Profile' },
    { title: 'Dr. Usman Ali', meta: 'Neuro Rehabilitation', description: '8+ years experience', image: 'https://picsum.photos/seed/tre-4/480/300', rating: '4.8 (64 reviews)', cta: 'View Profile' },
  ],
  howItWorksHeading: 'How It Works',
  howItWorks: [
    { step: 1, title: 'Book a Session', description: 'Choose a therapist, date and time.' },
    { step: 2, title: 'Join Online', description: 'Connect via secure video call.' },
    { step: 3, title: 'Get a Personalised Plan', description: 'Follow expert guidance and exercise plans.' },
    { step: 4, title: 'Track Progress', description: 'Stay on track with regular follow-ups.' },
  ],
  testimonialsHeading: 'What Our Users Say',
  testimonials: [
    { quote: 'After my knee surgery, the tele rehab sessions helped me recover faster. The therapist was very supportive and professional.', name: 'Sara M.', location: 'Patient' },
    { quote: 'Tele Rehab has made a huge difference in my life. I can now continue my therapy from home and feel more confident.', name: 'Maria S.', location: 'Patient' },
    { quote: 'The personalised exercise plan and progress tracking kept me motivated throughout my recovery.', name: 'Ali H.', location: 'Patient' },
  ],
  ctaHeading: 'Rehabilitation Support for a More Inclusive Tomorrow',
  ctaSubheading: 'Because every step forward matters.',
  ctaLabel: 'Book a Session',
  footerTagline: 'Healthier people. Stronger communities.',
};
