'use client';

import { useState } from 'react';
import {
  Search,
  HelpCircle,
  BookOpen,
  MessageCircle,
  Send,
  UserCircle,
  Settings,
  ClipboardList,
  GraduationCap,
  Users,
  Briefcase,
  MapPin,
  CreditCard,
  ShieldCheck,
  ChevronDown,
  Mail,
  Phone,
  Clock,
} from 'lucide-react';

const categories = [
  { icon: UserCircle, title: 'Account & Registration', description: 'Creating an account, profile settings, verification and more.' },
  { icon: Settings, title: 'Using the Platform', description: 'How to navigate, find services, and use key features.' },
  { icon: ClipboardList, title: 'Services & Bookings', description: 'Finding, booking and managing services like tele health, tele rehab and more.' },
  { icon: GraduationCap, title: 'Programs', description: 'Eligibility, application process and program details.' },
  { icon: Users, title: 'Community', description: 'Joining groups, participating in discussions and community guidelines.' },
  { icon: Briefcase, title: 'Jobs & Employment', description: 'Finding job opportunities and employer information.' },
  { icon: MapPin, title: 'Accessibility Map', description: 'Using the map, adding places and accessibility information.' },
  { icon: CreditCard, title: 'Payments & Subscriptions', description: 'Free vs premium, payment methods, invoices and refunds.' },
  { icon: ShieldCheck, title: 'Privacy & Security', description: 'Your data, security measures and privacy settings.' },
  { icon: HelpCircle, title: 'General', description: 'Other common questions about Ability Link.' },
];

const popularArticles = [
  'How to create an Ability Link account',
  'How to book a tele rehab session',
  'How to find accessible places near you',
  'How to apply for programs',
  'How to join a community group',
];

export function FaqsClient() {
  const [open, setOpen] = useState<number | null>(0);

  return (
    <>
      <section className="bg-gradient-to-b from-brand-50/70 to-white py-12">
        <div className="mx-auto max-w-page px-4 sm:px-6">
          <p className="text-xs font-bold uppercase tracking-[0.14em] text-brand-600">
            FAQs
          </p>
          <h1 className="balance mt-3 max-w-xl text-4xl font-extrabold leading-[1.08] text-slate-900 sm:text-5xl">
            Find Answers
            <br />
            <span className="text-brand-600">To Your Questions</span>
          </h1>
          <p className="mt-4 max-w-xl text-base text-slate-500">
            Get quick answers to common questions about Ability Link, our
            services, programs and how to make the most of the platform.
          </p>
          <div className="mt-6 flex max-w-xl items-center gap-2 rounded-full border border-slate-200 bg-white p-1.5 shadow-sm">
            <Search className="ml-3 h-4 w-4 text-slate-400" />
            <input
              type="text"
              placeholder="Search FAQs (e.g. account, booking, accessibility, jobs...)"
              className="w-full min-w-0 py-2 text-sm outline-none placeholder:text-slate-400"
            />
            <button className="shrink-0 rounded-full bg-brand-600 px-5 py-2 text-sm font-semibold text-white">
              Search
            </button>
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-page px-4 pb-16 sm:px-6">
        <div className="grid gap-10 lg:grid-cols-[1fr_320px]">
          <div>
            <h2 className="mb-1 text-2xl font-bold text-slate-900">
              Browse FAQs by Category
            </h2>
            <p className="mb-6 text-sm text-slate-500">
              Select a category to find relevant questions.
            </p>
            <div className="divide-y divide-slate-100 rounded-2xl border border-slate-100">
              {categories.map(({ icon: Icon, title, description }, i) => (
                <button
                  key={title}
                  type="button"
                  onClick={() => setOpen(open === i ? null : i)}
                  className="flex w-full items-center gap-4 p-4 text-left"
                >
                  <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-brand-50 text-brand-600">
                    <Icon className="h-4 w-4" />
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-sm font-semibold text-slate-900">
                      {title}
                    </span>
                    <span className="block text-xs text-slate-500">
                      {description}
                    </span>
                  </span>
                  <ChevronDown
                    className={`h-4 w-4 shrink-0 text-slate-400 transition ${open === i ? 'rotate-180' : ''}`}
                  />
                </button>
              ))}
            </div>
          </div>

          <aside className="space-y-5">
            <div className="rounded-2xl border border-slate-100 bg-brand-50/60 p-5">
              <h3 className="flex items-center gap-2 text-sm font-bold text-slate-900">
                <MessageCircle className="h-4 w-4 text-brand-600" />
                Can&rsquo;t find what you&rsquo;re looking for?
              </h3>
              <p className="mt-1 text-xs text-slate-500">
                Our support team is here to help you with any questions.
              </p>
              <button className="mt-3 w-full rounded-full bg-brand-600 py-2 text-sm font-semibold text-white">
                Contact Support
              </button>
            </div>

            <div className="rounded-2xl border border-slate-100 p-5">
              <h3 className="mb-3 flex items-center gap-2 text-sm font-bold text-slate-900">
                <BookOpen className="h-4 w-4 text-brand-600" />
                Popular Articles
              </h3>
              <ul className="space-y-2.5">
                {popularArticles.map((a) => (
                  <li key={a}>
                    <a href="#" className="text-sm text-slate-600 hover:text-brand-700">
                      {a} →
                    </a>
                  </li>
                ))}
              </ul>
            </div>

            <div className="rounded-2xl border border-slate-100 p-5">
              <h3 className="mb-3 text-sm font-bold text-slate-900">
                Need More Help?
              </h3>
              <div className="space-y-2.5 text-sm text-slate-600">
                <p className="flex items-center gap-2">
                  <MessageCircle className="h-4 w-4 text-brand-600" /> Live
                  Chat
                </p>
                <p className="flex items-center gap-2">
                  <Mail className="h-4 w-4 text-brand-600" />{' '}
                  support@abilitylink.org
                </p>
                <p className="flex items-center gap-2">
                  <Phone className="h-4 w-4 text-brand-600" /> +92 300 1234567
                </p>
                <p className="flex items-center gap-2 text-xs text-slate-400">
                  <Clock className="h-3.5 w-3.5" /> Mon–Fri, 9:00 AM – 6:00 PM (PKT)
                </p>
              </div>
            </div>
          </aside>
        </div>
      </section>

      <section className="mx-auto max-w-page px-4 pb-16 sm:px-6">
        <div className="flex flex-col items-start justify-between gap-4 rounded-3xl bg-brand-600 p-8 sm:flex-row sm:items-center">
          <div>
            <h2 className="text-xl font-bold text-white">
              Together for a More Inclusive Tomorrow
            </h2>
            <p className="mt-1 text-sm text-brand-100">
              Your questions help us build a better, more accessible world.
            </p>
          </div>
          <Send className="hidden h-8 w-8 text-white/60 sm:block" />
        </div>
      </section>
    </>
  );
}
