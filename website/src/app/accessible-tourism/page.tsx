import type { Metadata } from 'next';
import { VerticalPage } from '@/components/marketing/VerticalPage';
import { tourism } from '@/data/verticals/tourism';

export const metadata: Metadata = { title: 'Accessible Tourism' };

export default function TourismPage() {
  return <VerticalPage content={tourism} />;
}
