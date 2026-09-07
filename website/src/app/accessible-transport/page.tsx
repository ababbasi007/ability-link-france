import type { Metadata } from 'next';
import { VerticalPage } from '@/components/marketing/VerticalPage';
import { transport } from '@/data/verticals/transport';

export const metadata: Metadata = { title: 'Accessible Transport' };

export default function TransportPage() {
  return <VerticalPage content={transport} />;
}
