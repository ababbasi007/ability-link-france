import type { Metadata } from 'next';
import { VerticalPage } from '@/components/marketing/VerticalPage';
import { telerehab } from '@/data/verticals/telerehab';

export const metadata: Metadata = { title: 'Tele Rehab' };

export default function TelerehabPage() {
  return <VerticalPage content={telerehab} />;
}
