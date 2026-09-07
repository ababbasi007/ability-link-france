import type { Metadata } from 'next';
import { VerticalPage } from '@/components/marketing/VerticalPage';
import { services } from '@/data/verticals/services';

export const metadata: Metadata = { title: 'Services Marketplace' };

export default function ServicesPage() {
  return <VerticalPage content={services} />;
}
