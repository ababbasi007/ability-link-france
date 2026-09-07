import type { Metadata } from 'next';
import { VerticalPage } from '@/components/marketing/VerticalPage';
import { assistiveTechnology } from '@/data/verticals/assistiveTechnology';

export const metadata: Metadata = { title: 'Assistive Technology' };

export default function AssistiveTechnologyPage() {
  return <VerticalPage content={assistiveTechnology} />;
}
