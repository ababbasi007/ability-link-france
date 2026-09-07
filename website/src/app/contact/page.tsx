import type { Metadata } from 'next';
import { ComingSoon } from '@/components/marketing/ComingSoon';

export const metadata: Metadata = { title: 'Contact' };

export default function ContactPage() {
  return (
    <ComingSoon
      eyebrow="Contact"
      title="Contact Page Coming Soon"
      description="This page wasn't in the reviewed mockups yet — it's a placeholder so the main navigation works end to end while the Contact page design is finalized."
    />
  );
}
