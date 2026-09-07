import type { Metadata } from 'next';
import { AiAssistantClient } from './AiAssistantClient';

export const metadata: Metadata = { title: 'AI Assistant' };

export default function AiAssistantPage() {
  return <AiAssistantClient />;
}
