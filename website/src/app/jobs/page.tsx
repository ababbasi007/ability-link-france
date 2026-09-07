import type { Metadata } from 'next';
import { VerticalPage } from '@/components/marketing/VerticalPage';
import { jobs } from '@/data/verticals/jobs';

export const metadata: Metadata = { title: 'Jobs & Opportunities' };

export default function JobsPage() {
  return <VerticalPage content={jobs} />;
}
