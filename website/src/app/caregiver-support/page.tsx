import type { Metadata } from 'next';
import { VerticalPage } from '@/components/marketing/VerticalPage';
import { caregiver } from '@/data/verticals/caregiver';

export const metadata: Metadata = { title: 'Caregiver Support' };

export default function CaregiverPage() {
  return <VerticalPage content={caregiver} />;
}
