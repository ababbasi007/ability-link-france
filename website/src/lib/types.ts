import type { LucideIcon } from 'lucide-react';

export type BadgeColor =
  | 'blue'
  | 'purple'
  | 'rose'
  | 'emerald'
  | 'amber'
  | 'sky'
  | 'violet'
  | 'slate';

export interface QuickLink {
  icon: LucideIcon;
  label: string;
}

export interface CategoryTile {
  icon: LucideIcon;
  label: string;
  description?: string;
  color: BadgeColor;
}

export interface FeaturedItem {
  title: string;
  meta: string;
  description?: string;
  image: string;
  tag?: string;
  rating?: string;
  cta: string;
}

export interface HowItWorksStep {
  step: number;
  title: string;
  description: string;
}

export interface Testimonial {
  quote: string;
  name: string;
  location: string;
}

export interface VerticalPageContent {
  eyebrow: string;
  title: string;
  titleAccent: string;
  subtitle: string;
  heroImage: string;
  handwrittenCaption: string;
  searchPlaceholder: string;
  trustBadges: string[];
  quickLinks: QuickLink[];
  tabs: string[];
  categoriesHeading: string;
  categoriesSubheading: string;
  categories: CategoryTile[];
  featuredHeading: string;
  featuredSubheading: string;
  featured: FeaturedItem[];
  howItWorksHeading: string;
  howItWorks: HowItWorksStep[];
  testimonialsHeading: string;
  testimonials: Testimonial[];
  ctaHeading: string;
  ctaSubheading: string;
  ctaLabel: string;
  footerTagline: string;
}
