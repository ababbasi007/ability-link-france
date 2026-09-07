import type { Metadata } from 'next';
import { VerticalPage } from '@/components/marketing/VerticalPage';
import { benefits } from '@/data/verticals/benefits';

export const metadata: Metadata = { title: 'Benefits & Support' };

export default function BenefitsPage() {
  return <VerticalPage content={benefits} />;
}
