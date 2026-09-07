'use client';

import { useState } from 'react';
import {
  Bot,
  Send,
  Mic,
  Search,
  ListChecks,
  UserCheck,
  MapPin,
  Globe,
  FileText,
  ShieldAlert,
  Compass,
} from 'lucide-react';
import { CategoryPillTabs } from '@/components/marketing/CategoryPillTabs';

const prompts = [
  'Explain disability allowance in simple words',
  'How can I find accessible transport near me?',
  'What are good online courses for persons with disabilities?',
  'Suggest exercises for wheelchair users',
  'How to apply for a job with a disability?',
  'What travel destinations are wheelchair friendly?',
  'What documents do I need for legal support?',
  'Recommend assistive devices for hearing impairment',
];

const helpCards = [
  { icon: Search, title: 'Find Information', description: 'Get clear and reliable answers on a wide range of topics.' },
  { icon: ListChecks, title: 'Step-by-Step Guidance', description: 'Easy instructions for applications, bookings and services.' },
  { icon: UserCheck, title: 'Personalized Suggestions', description: 'Get recommendations tailored to your needs.' },
  { icon: MapPin, title: 'Local Resources', description: 'Find accessible services, organizations and support near you.' },
  { icon: FileText, title: 'Document Help', description: 'Understand and prepare required documents.' },
  { icon: Globe, title: 'Multilingual Support', description: 'Chat in your preferred language.' },
  { icon: ShieldAlert, title: 'Crisis Support', description: 'Get guidance on urgent situations and helplines.' },
  { icon: Compass, title: 'Learn & Explore', description: 'Discover new opportunities for education, jobs and independent living.' },
];

const commonQuestions = [
  'How can I apply for a disability card?',
  'What support is available for education?',
  'How to find a remote job?',
  'Which countries are best for accessible tourism?',
];

export function AiAssistantClient() {
  const [message, setMessage] = useState('');

  return (
    <>
      <section className="bg-gradient-to-b from-brand-50/70 to-white py-10 sm:py-14">
        <div className="mx-auto grid max-w-page gap-10 px-4 sm:px-6 lg:grid-cols-[1.1fr_0.9fr] lg:items-center">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.14em] text-brand-600">
              AI Assistant
            </p>
            <h1 className="balance mt-3 text-4xl font-extrabold leading-[1.08] text-slate-900 sm:text-5xl">
              Your AI Companion
              <br />
              <span className="text-brand-600">for a More Inclusive Tomorrow</span>
            </h1>
            <p className="mt-5 max-w-xl text-base leading-relaxed text-slate-500">
              Get instant answers, guidance and personalized support on
              accessibility, health, education, jobs, rights and more.
            </p>
            <div className="mt-6 flex flex-wrap gap-6">
              <span className="flex items-center gap-2 text-sm font-medium text-slate-600">
                <span className="grid h-8 w-8 place-items-center rounded-full bg-amber-100 text-amber-600">⚡</span>
                Instant Answers
              </span>
              <span className="flex items-center gap-2 text-sm font-medium text-slate-600">
                <UserCheck className="h-4 w-4 text-brand-600" />
                Personalized Support
              </span>
              <span className="flex items-center gap-2 text-sm font-medium text-slate-600">
                <ShieldAlert className="h-4 w-4 text-emerald-600" />
                Inclusive &amp; Safe
              </span>
            </div>
          </div>

          <div className="mx-auto flex w-full max-w-sm items-center justify-center">
            <div className="grid h-40 w-40 place-items-center rounded-full bg-brand-100">
              <Bot className="h-20 w-20 text-brand-600" strokeWidth={1.5} />
            </div>
          </div>
        </div>
      </section>

      <div className="mx-auto max-w-page px-4 sm:px-6">
        <CategoryPillTabs
          tabs={[
            'General Help',
            'Disability Support',
            'Health & Rehab',
            'Education',
            'Jobs & Career',
            'Services',
            'Travel & Tourism',
            'Rights & Legal',
            'Assistive Tech',
            'Caregiver Support',
          ]}
        />
      </div>

      <section className="mx-auto max-w-page px-4 pb-14 sm:px-6">
        <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
          <div className="flex flex-col rounded-3xl border border-slate-100 bg-brand-50/40 p-5">
            <div className="mb-4 flex items-center gap-3">
              <span className="grid h-9 w-9 place-items-center rounded-full bg-brand-600 text-white">
                <Bot className="h-4 w-4" />
              </span>
              <div>
                <p className="text-sm font-semibold text-slate-900">
                  Ability Link AI Assistant
                </p>
                <p className="text-xs text-slate-500">
                  Ask me anything. I&rsquo;m here to help.
                </p>
              </div>
              <span className="ml-auto flex items-center gap-1.5 text-xs font-medium text-emerald-600">
                <span className="h-2 w-2 rounded-full bg-emerald-500" />
                Online
              </span>
            </div>

            <div className="rounded-2xl bg-white p-4 shadow-sm">
              <p className="text-sm leading-relaxed text-slate-700">
                Hello! 👋 I can help you with information, guidance, and
                resources related to disability support, healthcare,
                education, jobs, accessible travel, legal rights, and more.
                What would you like to know today?
              </p>
              <div className="mt-3 flex flex-wrap gap-2">
                {[
                  'What government benefits can I get?',
                  'How to apply for a wheelchair?',
                  'Find accessible tourist places in Europe',
                  'How to start working from home?',
                  'What are my legal rights?',
                  'Suggest assistive technology for low vision',
                ].map((q) => (
                  <button
                    key={q}
                    type="button"
                    className="rounded-full border border-slate-200 bg-white px-3 py-1.5 text-xs font-medium text-slate-600 transition hover:border-brand-300 hover:text-brand-700"
                  >
                    {q}
                  </button>
                ))}
              </div>
            </div>

            <form
              className="mt-4 flex items-center gap-2 rounded-full border border-slate-200 bg-white p-1.5"
              onSubmit={(e) => e.preventDefault()}
            >
              <input
                type="text"
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                placeholder="Type your question here..."
                className="w-full min-w-0 py-2 pl-3 text-sm outline-none placeholder:text-slate-400"
              />
              <button
                type="submit"
                aria-label="Send"
                className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-brand-600 text-white transition hover:bg-brand-700"
              >
                <Send className="h-4 w-4" />
              </button>
            </form>
            <p className="mt-2 text-center text-[11px] text-slate-400">
              AI responses are for informational purposes only. Always
              consult a qualified professional for medical, legal or
              financial advice.
            </p>
          </div>

          <aside className="space-y-4">
            <div className="rounded-2xl border border-slate-100 p-5">
              <h3 className="mb-3 text-sm font-bold text-slate-900">
                Try These Prompts
              </h3>
              <ul className="space-y-2">
                {prompts.map((p) => (
                  <li key={p}>
                    <button
                      type="button"
                      onClick={() => setMessage(p)}
                      className="w-full rounded-lg px-2 py-1.5 text-left text-xs text-slate-600 transition hover:bg-brand-50 hover:text-brand-700"
                    >
                      {p} →
                    </button>
                  </li>
                ))}
              </ul>
            </div>

            <div className="rounded-2xl border border-slate-100 p-5 text-center">
              <span className="mx-auto mb-2 grid h-10 w-10 place-items-center rounded-full bg-violet-100 text-violet-600">
                <Mic className="h-5 w-5" />
              </span>
              <h3 className="text-sm font-bold text-slate-900">
                Speak or Type
              </h3>
              <p className="mt-1 text-xs text-slate-500">
                You can also use voice to ask your questions.
              </p>
              <button
                type="button"
                className="mt-3 w-full rounded-full border border-slate-200 py-2 text-sm font-semibold text-slate-700 transition hover:border-brand-300 hover:text-brand-700"
              >
                Tap to Speak
              </button>
            </div>
          </aside>
        </div>
      </section>

      <section className="bg-slate-50/70 py-14">
        <div className="mx-auto max-w-page px-4 sm:px-6">
          <h2 className="mb-1 text-2xl font-bold text-slate-900">
            What Can I Help You With?
          </h2>
          <p className="mb-8 text-sm text-slate-500">
            Explore the ways our AI Assistant can support you.
          </p>
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
            {helpCards.map(({ icon: Icon, title, description }) => (
              <div
                key={title}
                className="rounded-2xl border border-slate-100 bg-white p-5"
              >
                <span className="grid h-10 w-10 place-items-center rounded-full bg-brand-50 text-brand-600">
                  <Icon className="h-5 w-5" />
                </span>
                <h3 className="mt-3 text-sm font-semibold text-slate-900">
                  {title}
                </h3>
                <p className="mt-1 text-xs leading-relaxed text-slate-500">
                  {description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-page px-4 py-14 sm:px-6">
        <h2 className="mb-6 text-2xl font-bold text-slate-900">
          Common Questions
        </h2>
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {commonQuestions.map((q) => (
            <button
              key={q}
              type="button"
              className="rounded-xl border border-slate-200 px-4 py-3 text-left text-sm font-medium text-slate-700 transition hover:border-brand-300 hover:text-brand-700"
            >
              {q}
            </button>
          ))}
        </div>
      </section>
    </>
  );
}
