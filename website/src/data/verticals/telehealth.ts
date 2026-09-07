import { Video, Calendar, FileText, ClipboardCheck, Users, Stethoscope, Brain, Accessibility, HeartPulse, PersonStanding, Baby } from 'lucide-react';
import type { VerticalPageContent } from '@/lib/types';

export const telehealth: VerticalPageContent = {
  eyebrow: 'Tele Health',
  title: 'Quality Healthcare',
  titleAccent: 'Without Barriers',
  subtitle:
    'Connect with licensed doctors, specialists and mental health professionals from the comfort of your home. Accessible, affordable and compassionate care for everyone.',
  heroImage: 'https://picsum.photos/seed/telehealth/800/600',
  handwrittenCaption: 'Healthcare\nFor a Brighter Tomorrow',
  searchPlaceholder: 'Search doctors, specialties or conditions',
  trustBadges: ['Verified Healthcare Professionals', 'Secure & Confidential', 'Accessible for All', 'Multiple Specialties'],
  quickLinks: [
    { icon: Video, label: 'Video Consultations' },
    { icon: Calendar, label: 'Book Appointments' },
    { icon: FileText, label: 'E-Prescriptions' },
    { icon: ClipboardCheck, label: 'Health Records' },
    { icon: Users, label: 'Follow-up Care' },
  ],
  tabs: ['General Medicine', 'Specialist Care', 'Mental Health', 'Rehabilitation Care', 'Child Health', 'Senior Citizen Care', 'Disability-Specific'],
  categoriesHeading: 'Our Telehealth Services',
  categoriesSubheading: 'Comprehensive care designed for your needs.',
  categories: [
    { icon: Stethoscope, label: 'General Medicine', description: 'Consult for common health concerns', color: 'blue' },
    { icon: HeartPulse, label: 'Specialist Care', description: 'Access to specialists (cardiology, endocrinology, etc.)', color: 'rose' },
    { icon: Brain, label: 'Mental Health', description: 'Talk to psychologists and counsellors', color: 'emerald' },
    { icon: Accessibility, label: 'Rehabilitation Care', description: 'Medical guidance alongside physiotherapy plans', color: 'violet' },
    { icon: Baby, label: 'Child Health', description: 'Pediatric consultations for your little ones', color: 'amber' },
    { icon: PersonStanding, label: 'Senior Citizen Care', description: 'Age-friendly healthcare support', color: 'sky' },
    { icon: Accessibility, label: 'Disability-Specific Care', description: 'Healthcare tailored to people with disabilities', color: 'rose' },
  ],
  featuredHeading: 'Featured Healthcare Professionals',
  featuredSubheading: 'Consult with verified and experienced doctors.',
  featured: [
    { title: 'Dr. Sara Ahmed', meta: 'General Physician', description: '10+ years experience', image: 'https://picsum.photos/seed/th-1/480/300', rating: '4.9 (120 reviews)', cta: 'Book Now' },
    { title: 'Dr. Imran Khan', meta: 'Orthopedic Specialist', description: '12+ years experience', image: 'https://picsum.photos/seed/th-2/480/300', rating: '4.8 (98 reviews)', cta: 'Book Now' },
    { title: 'Dr. Ayesha Malik', meta: 'Psychologist', description: '8+ years experience', image: 'https://picsum.photos/seed/th-3/480/300', rating: '4.9 (76 reviews)', cta: 'Book Now' },
    { title: 'Dr. Usman Raza', meta: 'Cardiologist', description: '15+ years experience', image: 'https://picsum.photos/seed/th-4/480/300', rating: '4.8 (64 reviews)', cta: 'Book Now' },
  ],
  howItWorksHeading: 'How It Works',
  howItWorks: [
    { step: 1, title: 'Book an Appointment', description: 'Choose a doctor, date and time.' },
    { step: 2, title: 'Start a Video Consultation', description: 'Join through our secure platform.' },
    { step: 3, title: 'Get Care & Prescription', description: 'Receive medical advice and reports.' },
    { step: 4, title: 'Follow Up', description: 'Track your progress and book follow-ups.' },
  ],
  testimonialsHeading: 'Your Health, Our Priority',
  testimonials: [
    { quote: 'I was able to consult a specialist without leaving home. It saved me time and made healthcare accessible.', name: 'Fatima N.', location: 'Islamabad' },
    { quote: 'The video consultation felt personal and the doctor was very understanding of my accessibility needs.', name: 'Zainab A.', location: 'Karachi' },
    { quote: 'Getting a prescription and follow-up care online has been a huge relief for my family.', name: 'Ahmed L.', location: 'Lahore' },
  ],
  ctaHeading: 'Better Health. A More Inclusive Tomorrow.',
  ctaSubheading: 'Accessible healthcare for every ability, at every stage of life.',
  ctaLabel: 'Book a Consultation',
  footerTagline: 'Healthier people. Stronger communities.',
};
