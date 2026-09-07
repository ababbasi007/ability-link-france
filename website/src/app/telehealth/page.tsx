import type { Metadata } from 'next';
import { VerticalPage } from '@/components/marketing/VerticalPage';
import { telehealth } from '@/data/verticals/telehealth';

export const metadata: Metadata = { title: 'Tele Health' };

export default function TelehealthPage() {
  return <VerticalPage content={telehealth} />;
}
