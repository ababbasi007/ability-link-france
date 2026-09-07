import type { Metadata } from 'next';
import { ComingSoon } from '@/components/marketing/ComingSoon';

export const metadata: Metadata = { title: 'Privacy Policy' };

export default function PrivacyPage() {
  return (
    <ComingSoon
      eyebrow="Legal"
      title="Privacy Policy"
      description="Placeholder page — publish the finalized privacy policy here before launch."
    />
  );
}
