import type { Metadata } from 'next';
import { ComingSoon } from '@/components/marketing/ComingSoon';

export const metadata: Metadata = { title: 'About Us' };

export default function AboutPage() {
  return (
    <ComingSoon
      eyebrow="About Us"
      title="Our Story is Still Being Written"
      description="This page wasn't in the reviewed mockups yet — it's a placeholder so the main navigation works end to end while the About page design is finalized."
    />
  );
}
