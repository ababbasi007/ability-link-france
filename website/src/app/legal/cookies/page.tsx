import type { Metadata } from 'next';
import { ComingSoon } from '@/components/marketing/ComingSoon';

export const metadata: Metadata = { title: 'Cookie Policy' };

export default function CookiePolicyPage() {
  return (
    <ComingSoon
      eyebrow="Legal"
      title="Cookie Policy"
      description="Placeholder page — publish the finalized cookie policy here before launch."
    />
  );
}
