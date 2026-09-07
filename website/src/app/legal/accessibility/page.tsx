import type { Metadata } from 'next';
import { ComingSoon } from '@/components/marketing/ComingSoon';

export const metadata: Metadata = { title: 'Accessibility Statement' };

export default function AccessibilityStatementPage() {
  return (
    <ComingSoon
      eyebrow="Legal"
      title="Accessibility Statement"
      description="Placeholder page — publish the finalized accessibility conformance statement here before launch."
    />
  );
}
