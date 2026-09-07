import type { Metadata } from 'next';
import { ComingSoon } from '@/components/marketing/ComingSoon';

export const metadata: Metadata = { title: 'Programs' };

export default function ProgramsPage() {
  return (
    <ComingSoon
      eyebrow="Programs"
      title="Programs Page Coming Soon"
      description="This page wasn't in the reviewed mockups yet — it's a placeholder so the main navigation works end to end while the Programs page design is finalized."
    />
  );
}
