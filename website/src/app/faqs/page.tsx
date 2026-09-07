import type { Metadata } from 'next';
import { FaqsClient } from './FaqsClient';

export const metadata: Metadata = { title: 'FAQs' };

export default function FaqsPage() {
  return <FaqsClient />;
}
