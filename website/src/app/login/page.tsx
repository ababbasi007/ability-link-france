import type { Metadata } from 'next';
import { ComingSoon } from '@/components/marketing/ComingSoon';

export const metadata: Metadata = { title: 'Log In' };

export default function LoginPage() {
  return (
    <ComingSoon
      eyebrow="Log In"
      title="Login Page Coming Soon"
      description="This wasn't part of the reviewed mockups — the sign-up flow (/signup) is built; wire this page to Firebase Auth alongside it."
    />
  );
}
