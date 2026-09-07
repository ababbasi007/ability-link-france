import type { Metadata } from 'next';
import { VerticalPage } from '@/components/marketing/VerticalPage';
import { education } from '@/data/verticals/education';

export const metadata: Metadata = { title: 'Accessible Education' };

export default function EducationPage() {
  return <VerticalPage content={education} />;
}
