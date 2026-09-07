import type { Metadata } from 'next';
import { ComingSoon } from '@/components/marketing/ComingSoon';

export const metadata: Metadata = { title: 'Terms of Service' };

export default function TermsPage() {
  return (
    <ComingSoon
      eyebrow="Legal"
      title="Terms of Service"
      description="Placeholder page — publish the finalized terms of service here before launch."
    />
  );
}
