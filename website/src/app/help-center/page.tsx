import type { Metadata } from 'next';
import {
  Search,
  UserCircle,
  ClipboardList,
  GraduationCap,
  Users,
  Accessibility,
  Laptop,
  ShieldCheck,
  CreditCard,
  Handshake,
  HelpCircle,
  MessageCircle,
  Mail,
  Phone,
  Clock,
  Send,
} from 'lucide-react';

export const metadata: Metadata = { title: 'Help Center' };

const topics = [
  { icon: UserCircle, title: 'Getting Started', description: 'Accounts, profiles and basics' },
  { icon: ClipboardList, title: 'Services', description: 'Booking, payments and service details' },
  { icon: GraduationCap, title: 'Programs', description: 'Program information and eligibility' },
  { icon: Users, title: 'Community', description: 'Groups, events and participation' },
  { icon: Accessibility, title: 'Accessibility', description: 'Using the platform with accessibility tools' },
  { icon: Laptop, title: 'Technical Support', description: 'App issues, device compatibility' },
  { icon: ShieldCheck, title: 'Privacy & Security', description: 'Your data and account security' },
  { icon: CreditCard, title: 'Billing & Payments', description: 'Subscriptions and payments' },
  { icon: Handshake, title: 'Partnerships', description: 'For organizations and collaborators' },
  { icon: HelpCircle, title: 'General', description: 'Others / miscellaneous questions' },
];

const popularArticles = [
  { title: 'How to create an Ability Link account', description: 'Step-by-step guide to sign up and set up your profile.' },
  { title: 'How to book a service', description: 'Learn how to find and book services like tele rehab, tele health and more.' },
  { title: 'Is Ability Link free to use?', description: 'Information about free vs premium features.' },
  { title: 'How to join a community group', description: 'Find and join groups based on your interests.' },
  { title: 'How to use accessibility features', description: 'Tips for using screen readers, large text and other tools.' },
];

export default function HelpCenterPage() {
  return (
    <>
      <section className="bg-gradient-to-b from-brand-50/70 to-white py-12">
        <div className="mx-auto max-w-page px-4 sm:px-6">
          <p className="text-xs font-bold uppercase tracking-[0.14em] text-brand-600">
            Help Center
          </p>
          <h1 className="balance mt-3 max-w-xl text-4xl font-extrabold leading-[1.08] text-slate-900 sm:text-5xl">
            How Can We
            <br />
            <span className="text-brand-600">Help You?</span>
          </h1>
          <p className="mt-4 max-w-xl text-base text-slate-500">
            Find answers, learn how to use Ability Link, or get in touch with
            our support team. We&rsquo;re here to make your experience simple
            and accessible.
          </p>
          <div className="mt-6 flex max-w-xl items-center gap-2 rounded-full border border-slate-200 bg-white p-1.5 shadow-sm">
            <Search className="ml-3 h-4 w-4 text-slate-400" />
            <input
              type="text"
              placeholder="Search for help articles, guides, or keywords..."
              className="w-full min-w-0 py-2 text-sm outline-none placeholder:text-slate-400"
            />
            <button className="shrink-0 rounded-full bg-brand-600 px-5 py-2 text-sm font-semibold text-white">
              Search
            </button>
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-page px-4 py-14 sm:px-6">
        <h2 className="mb-1 text-2xl font-bold text-slate-900">
          Browse Help Topics
        </h2>
        <p className="mb-6 text-sm text-slate-500">
          Find the information you need by topic.
        </p>
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-5">
          {topics.map(({ icon: Icon, title, description }) => (
            <div
              key={title}
              className="flex flex-col items-center gap-2 rounded-2xl border border-slate-100 p-5 text-center"
            >
              <span className="grid h-11 w-11 place-items-center rounded-full bg-brand-50 text-brand-600">
                <Icon className="h-5 w-5" />
              </span>
              <span className="text-sm font-semibold text-slate-900">
                {title}
              </span>
              <span className="text-xs text-slate-500">{description}</span>
            </div>
          ))}
        </div>
      </section>

      <section className="mx-auto max-w-page px-4 pb-16 sm:px-6">
        <div className="grid gap-10 lg:grid-cols-[1fr_320px]">
          <div>
            <h2 className="mb-1 text-2xl font-bold text-slate-900">
              Popular Articles
            </h2>
            <p className="mb-6 text-sm text-slate-500">
              Quick answers to common questions.
            </p>
            <ul className="divide-y divide-slate-100 rounded-2xl border border-slate-100">
              {popularArticles.map((a) => (
                <li key={a.title} className="flex items-center justify-between gap-3 p-4">
                  <div>
                    <p className="text-sm font-semibold text-slate-900">
                      {a.title}
                    </p>
                    <p className="text-xs text-slate-500">{a.description}</p>
                  </div>
                  <span className="shrink-0 text-slate-300">→</span>
                </li>
              ))}
            </ul>
          </div>

          <aside className="space-y-5">
            <div className="rounded-2xl border border-slate-100 p-5">
              <h3 className="mb-3 text-sm font-bold text-slate-900">
                Still Need Help?
              </h3>
              <p className="mb-3 text-xs text-slate-500">
                Our support team is ready to assist you.
              </p>
              <div className="space-y-2.5 text-sm text-slate-600">
                <p className="flex items-center gap-2">
                  <MessageCircle className="h-4 w-4 text-brand-600" /> Live Chat
                </p>
                <p className="flex items-center gap-2">
                  <Mail className="h-4 w-4 text-brand-600" />{' '}
                  support@abilitylink.org
                </p>
                <p className="flex items-center gap-2">
                  <Phone className="h-4 w-4 text-brand-600" /> +92 300 1234567
                </p>
              </div>
              <p className="mt-3 flex items-center gap-2 text-xs text-slate-400">
                <Clock className="h-3.5 w-3.5" /> Mon–Fri, 9:00 AM – 6:00 PM
                (PKT) · We usually respond within 24 hours.
              </p>
            </div>

            <div className="rounded-2xl border border-slate-100 p-5">
              <h3 className="mb-2 text-sm font-bold text-slate-900">
                Submit a Support Request
              </h3>
              <p className="mb-3 text-xs text-slate-500">
                Can&rsquo;t find what you&rsquo;re looking for? Send us a
                message.
              </p>
              <button className="flex w-full items-center justify-center gap-2 rounded-full bg-brand-600 py-2.5 text-sm font-semibold text-white">
                <Send className="h-4 w-4" />
                Submit a Request
              </button>
            </div>
          </aside>
        </div>
      </section>
    </>
  );
}
