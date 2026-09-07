export const mainNav = [
  { href: '/', label: 'Home' },
  { href: '/about', label: 'About Us' },
  { href: '/services', label: 'Services', dropdown: true },
  { href: '/programs', label: 'Programs' },
  { href: '/community', label: 'Community' },
  { href: '/resources', label: 'Resources', dropdown: true },
  { href: '/contact', label: 'Contact' },
];

export const footerQuickLinks = [
  { href: '/about', label: 'About Us' },
  { href: '/about#how', label: 'How it Works' },
  { href: '/programs', label: 'Programs' },
  { href: '/community', label: 'Community' },
  { href: '/contact', label: 'Contact' },
];

export const footerServices = [
  { href: '/ability-map', label: 'Ability Map' },
  { href: '/telerehab', label: 'Tele Rehab' },
  { href: '/telehealth', label: 'Tele Health' },
  { href: '/education', label: 'Accessible Education' },
  { href: '/jobs', label: 'Jobs' },
  { href: '/accessible-tourism', label: 'Accessible Tourism' },
];

export const footerResources = [
  { href: '/resources', label: 'Blog' },
  { href: '/resources#guides', label: 'Guides' },
  { href: '/community#events', label: 'Events' },
  { href: '/faqs', label: 'FAQs' },
  { href: '/help-center', label: 'Help Center' },
];

export const footerSupport = [
  { href: '/help-center', label: 'Help & Support' },
  { href: '/contact', label: 'Contact Us' },
  { href: '/legal/accessibility', label: 'Accessibility' },
  { href: '/legal/privacy', label: 'Privacy Policy' },
  { href: '/legal/terms', label: 'Terms of Service' },
];

/** @deprecated Prefer the home footer columns; kept for older pages. */
export const footerColumns = [
  {
    heading: 'Quick Links',
    links: footerQuickLinks,
  },
  {
    heading: 'Services',
    links: footerServices,
  },
  {
    heading: 'Resources',
    links: footerResources,
  },
  {
    heading: 'Support',
    links: footerSupport,
  },
];

export const socialLinks = [
  { href: '#', label: 'Facebook' },
  { href: '#', label: 'X' },
  { href: '#', label: 'Instagram' },
  { href: '#', label: 'LinkedIn' },
];
