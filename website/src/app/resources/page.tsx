import type { Metadata } from 'next';
import Image from 'next/image';
import { Hero } from '@/components/marketing/Hero';
import { CategoryPillTabs } from '@/components/marketing/CategoryPillTabs';
import { CategoryGrid } from '@/components/marketing/CategoryGrid';
import { SectionHeader } from '@/components/marketing/SectionHeader';
import {
  Newspaper,
  BookOpen,
  Video,
  Link2,
  Lightbulb,
  Megaphone,
  FileText,
  Scale,
  BarChart3,
  Wrench,
  Users,
  Mail,
  Calendar,
} from 'lucide-react';

export const metadata: Metadata = { title: 'News & Resources' };

const news = [
  { tag: 'Global', date: 'Sep 4, 2026', title: 'EU Launches New Accessibility Standards for Air Travel', description: 'New rules aim to make air travel more inclusive for persons with disabilities across Europe.' },
  { tag: 'Pakistan', date: 'Sep 3, 2026', title: 'Pakistan Announces Enhanced Disability Allowance', description: 'Government increases monthly allowance and expands coverage for persons with disabilities.' },
  { tag: 'Technology', date: 'Sep 2, 2026', title: 'New AI-Powered Prosthetics Offer Greater Mobility', description: 'Innovative low-cost prosthetics use AI to adapt to natural movement, improving independence.' },
  { tag: 'Health', date: 'Aug 30, 2026', title: 'Study Shows Tele-Rehabilitation Improves Quality of Life', description: 'Global research highlights the positive impact of online rehabilitation services.' },
  { tag: 'Inspiration', date: 'Aug 28, 2026', title: 'Pakistani Athlete Wins Gold at Para Asian Games', description: 'A story of resilience and determination inspiring millions across the region.' },
  { tag: 'Accessible Tourism', date: 'Aug 25, 2026', title: 'Top 10 Accessible Travel Destinations in 2026', description: 'Explore beautiful destinations working towards a more inclusive tourism experience.' },
];

const featuredResources = [
  'Disability Rights Guide (Pakistan)',
  'Assistive Technology Buying Guide',
  'Accessible Travel Checklist',
  'Employment Rights for Persons with Disabilities',
  'Tele-Rehabilitation Best Practices',
];

const videoResources = [
  { title: 'How to Apply for Disability Card in Pakistan', duration: '8:24' },
  { title: 'Accessible Travel Tips', duration: '6:15' },
  { title: 'Understanding Prosthetics', duration: '10:12' },
];

const categories = [
  { icon: BookOpen, label: 'Guides & Handbooks', description: 'Step-by-step information', color: 'emerald' as const },
  { icon: FileText, label: 'Forms & Documents', description: 'Downloadable forms', color: 'blue' as const },
  { icon: Scale, label: 'Policies & Laws', description: 'National and international resources', color: 'violet' as const },
  { icon: BarChart3, label: 'Research & Reports', description: 'Studies and publications', color: 'sky' as const },
  { icon: Wrench, label: 'Tools & Apps', description: 'Useful digital tools', color: 'blue' as const },
  { icon: Users, label: 'NGO & Support Organizations', description: 'Find organizations near you', color: 'rose' as const },
  { icon: Megaphone, label: 'Awareness Campaigns', description: 'Promoting inclusion', color: 'amber' as const },
  { icon: Mail, label: 'Newsletters', description: 'Monthly updates', color: 'purple' as const },
];

const events = [
  { date: 'Sep 10', title: 'Inclusive Education Webinar', meta: 'Online · 10:00 AM (PKT)' },
  { date: 'Sep 15', title: 'Assistive Technology Expo', meta: 'Lahore, Pakistan · 10:00 AM (PKT)' },
  { date: 'Sep 22', title: 'Accessible Tourism Workshop', meta: 'Online · 4:00 PM (PKT)' },
];

export default function ResourcesPage() {
  return (
    <>
      <Hero
        eyebrow="News & Resources"
        title="Stay Informed."
        titleAccent="Build a Brighter Tomorrow."
        subtitle="Latest news, trusted resources and practical information for a more inclusive and accessible world."
        image="https://picsum.photos/seed/resources/800/600"
        handwrittenCaption={'Knowledge Creates\nOpportunities'}
        searchPlaceholder="Search news, articles, guides, videos (e.g. disability rights, accessible travel)"
        trustBadges={[]}
        quickLinks={[
          { icon: Newspaper, label: 'Latest News' },
          { icon: BookOpen, label: 'Guides & Publications' },
          { icon: Video, label: 'Videos & Webinars' },
          { icon: Link2, label: 'Useful Links' },
          { icon: Lightbulb, label: 'Tips & Awareness' },
          { icon: Megaphone, label: 'Campaigns & Events' },
        ]}
      />

      <div className="mx-auto max-w-page px-4 sm:px-6">
        <CategoryPillTabs
          tabs={[
            'All',
            'Disability Rights',
            'Health & Rehab',
            'Education',
            'Jobs & Employment',
            'Accessible Travel',
            'Assistive Technology',
            'Government Updates',
            'Research & Reports',
            'Stories & Inspiration',
          ]}
        />
      </div>

      <section className="mx-auto max-w-page px-4 pb-14 sm:px-6">
        <div className="grid gap-10 lg:grid-cols-[1fr_320px]">
          <div>
            <SectionHeader
              title="Latest News"
              subtitle="Stay updated with the latest developments from around the world."
              viewAllHref="#"
            />
            <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
              {news.map((item) => (
                <article
                  key={item.title}
                  className="flex flex-col overflow-hidden rounded-2xl border border-slate-100 shadow-sm shadow-slate-100"
                >
                  <div className="relative aspect-[16/10] w-full">
                    <Image
                      src={`https://picsum.photos/seed/news-${item.title.slice(0, 6)}/400/260`}
                      alt=""
                      fill
                      sizes="360px"
                      className="object-cover"
                    />
                    <span className="absolute left-3 top-3 rounded-full bg-brand-700/90 px-2.5 py-1 text-[11px] font-semibold text-white">
                      {item.tag}
                    </span>
                    <span className="absolute right-3 top-3 rounded-full bg-white/90 px-2.5 py-1 text-[11px] font-medium text-slate-600">
                      {item.date}
                    </span>
                  </div>
                  <div className="flex flex-1 flex-col gap-2 p-4">
                    <h3 className="text-sm font-semibold leading-snug text-slate-900">
                      {item.title}
                    </h3>
                    <p className="line-clamp-2 text-xs text-slate-500">
                      {item.description}
                    </p>
                    <span className="mt-auto pt-1 text-xs font-semibold text-brand-700">
                      Read More →
                    </span>
                  </div>
                </article>
              ))}
            </div>
          </div>

          <aside className="space-y-5">
            <div className="rounded-2xl border border-slate-100 bg-brand-50/60 p-5">
              <h3 className="mb-1 text-sm font-bold text-slate-900">
                Featured Resources
              </h3>
              <p className="mb-3 text-xs text-slate-500">
                Helpful guides, toolkits and information for everyday use.
              </p>
              <ul className="space-y-2.5">
                {featuredResources.map((r) => (
                  <li
                    key={r}
                    className="flex items-center justify-between gap-2 text-sm text-slate-700"
                  >
                    <span className="flex items-center gap-2">
                      <FileText className="h-4 w-4 shrink-0 text-brand-600" />
                      {r}
                    </span>
                    <span className="shrink-0 rounded border border-slate-300 px-1.5 py-0.5 text-[10px] font-semibold text-slate-500">
                      PDF
                    </span>
                  </li>
                ))}
              </ul>
            </div>

            <div className="rounded-2xl border border-slate-100 p-5">
              <h3 className="mb-3 text-sm font-bold text-slate-900">
                Video Resources
              </h3>
              <ul className="space-y-3">
                {videoResources.map((v) => (
                  <li key={v.title} className="flex items-center gap-3">
                    <span className="grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-rose-100 text-rose-600">
                      <Video className="h-4 w-4" />
                    </span>
                    <span className="text-sm text-slate-700">{v.title}</span>
                    <span className="ml-auto shrink-0 text-xs text-slate-400">
                      {v.duration}
                    </span>
                  </li>
                ))}
              </ul>
            </div>

            <div className="rounded-2xl bg-brand-600 p-5 text-white">
              <h3 className="text-sm font-bold">Subscribe to Updates</h3>
              <p className="mt-1 text-xs text-brand-100">
                Get the latest news, resources and opportunities delivered to your inbox.
              </p>
              <form className="mt-3 flex flex-col gap-2">
                <input
                  type="email"
                  placeholder="Enter your email address"
                  className="rounded-full px-4 py-2 text-sm text-slate-800 outline-none"
                />
                <button
                  type="submit"
                  className="rounded-full bg-white px-4 py-2 text-sm font-semibold text-brand-700"
                >
                  Subscribe
                </button>
              </form>
            </div>
          </aside>
        </div>
      </section>

      <CategoryGrid
        heading="Explore Resources by Category"
        subheading="Find curated information, tools and links on topics that matter to you."
        items={categories}
      />

      <section className="mx-auto max-w-page px-4 pb-16 sm:px-6">
        <SectionHeader title="Upcoming Events & Webinars" subtitle="Join events, webinars and awareness campaigns." viewAllHref="#" />
        <div className="grid gap-4 sm:grid-cols-3">
          {events.map((e) => (
            <div
              key={e.title}
              className="flex items-start gap-4 rounded-2xl border border-slate-100 p-4"
            >
              <div className="flex h-14 w-14 shrink-0 flex-col items-center justify-center rounded-xl bg-brand-50 text-brand-700">
                <Calendar className="h-4 w-4" />
                <span className="text-xs font-bold">{e.date}</span>
              </div>
              <div>
                <h3 className="text-sm font-semibold text-slate-900">
                  {e.title}
                </h3>
                <p className="mt-0.5 text-xs text-slate-500">{e.meta}</p>
                <span className="mt-2 inline-block rounded-full border border-brand-200 px-3 py-1 text-xs font-semibold text-brand-700">
                  View Details
                </span>
              </div>
            </div>
          ))}
        </div>
      </section>
    </>
  );
}
