import type { Metadata } from 'next';
import { VerticalPage } from '@/components/marketing/VerticalPage';
import { rightsLegal } from '@/data/verticals/rightsLegal';

export const metadata: Metadata = { title: 'Rights & Legal Support' };

export default function RightsLegalPage() {
  return <VerticalPage content={rightsLegal} />;
}
