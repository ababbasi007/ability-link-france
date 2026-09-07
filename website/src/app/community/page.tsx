import type { Metadata } from 'next';
import Link from 'next/link';
import {
  Calendar,
  UserCheck as GroupIcon,
  MessageCircle,
  Heart,
} from 'lucide-react';
import { CategoryPillTabs } from '@/components/marketing/CategoryPillTabs';
import { SectionHeader } from '@/components/marketing/SectionHeader';
import { BottomCta } from '@/components/marketing/BottomCta';

export const metadata: Metadata = { title: 'Community' };

const discussions = [
  { title: 'Tips for accessible travel in Turkey?', author: 'Ayesha K.', time: '2 hours ago', comments: 12, likes: 28, tag: 'Accessible Tourism' },
  { title: 'Best exercises after knee surgery?', author: 'Usman R.', time: '5 hours ago', comments: 18, likes: 35, tag: 'Post-Surgical Recovery' },
  { title: 'Online learning resources for graphic design', author: 'Sara M.', time: '1 day ago', comments: 9, likes: 22, tag: 'Accessible Education' },
  { title: 'Remote job opportunities for people with disabilities', author: 'Bilal A.', time: '1 day ago', comments: 25, likes: 47, tag: 'Jobs & Opportunities' },
  { title: 'How do you manage daily life with limited mobility?', author: 'Imran S.', time: '2 days ago', comments: 14, likes: 31, tag: 'Daily Living' },
];

const events = [
  { title: 'Live Webinar: Accessibility at Work', badge: 'Online', date: 'Fri, 12 Sep 2026', time: '5:00 PM (PKT)' },
  { title: 'Community Meet-Up Islamabad', badge: 'In-Person', date: 'Sun, 20 Sep 2026', time: '10:00 AM (PKT)' },
  { title: 'Tele Rehab Group Session', badge: 'Online', date: 'Tue, 22 Sep 2026', time: '4:00 PM (PKT)' },
];

const groups = [
  { name: 'Disability Support', members: '1.2K members' },
  { name: 'Caregivers Network', members: '980 members' },
  { name: 'Accessible Travel', members: '760 members' },
  { name: 'Remote Workers', members: '1.1K members' },
  { name: 'Parents of Children with Disabilities', members: '650 members' },
];

const stories = [
  { quote: 'Ability Link helped me find accessible travel options and I finally took my dream trip!', name: 'Zainab F.', role: 'Traveler & Advocate' },
  { quote: 'Through this community I found support after surgery. The advice and encouragement made a big difference.', name: 'Ali R.', role: 'Community Member' },
  { quote: 'It’s amazing to be part of a community where everyone understands and supports each other.', name: 'Hassan M.', role: 'Senior Member' },
];

export default function CommunityPage() {
  return (
    <>
      <section className="bg-gradient-to-b from-brand-50/70 to-white py-12">
        <div className="mx-auto max-w-page px-4 text-center sm:px-6">
          <p className="text-xs font-bold uppercase tracking-[0.14em] text-brand-600">
            Community
          </p>
          <h1 className="balance mx-auto mt-3 max-w-2xl text-4xl font-extrabold leading-[1.08] text-slate-900 sm:text-5xl">
            Stronger Together.
            <br />
            <span className="text-brand-600">A More Inclusive World.</span>
          </h1>
          <p className="mx-auto mt-5 max-w-xl text-base leading-relaxed text-slate-500">
            A safe and supportive community for people with disabilities,
            senior citizens, caregivers and allies. Share, learn, connect and
            grow — because everyone belongs.
          </p>
          <div className="mt-7 flex flex-wrap items-center justify-center gap-3">
            <Link
              href="/signup"
              className="rounded-full bg-brand-600 px-6 py-3 text-sm font-semibold text-white transition hover:bg-brand-700"
            >
              Join the Community
            </Link>
            <button
              type="button"
              className="rounded-full border border-slate-300 px-6 py-3 text-sm font-semibold text-slate-700 transition hover:border-brand-300"
            >
              How It Works
            </button>
          </div>
        </div>
      </section>

      <div className="mx-auto max-w-page px-4 sm:px-6">
        <CategoryPillTabs
          tabs={['All Posts', 'Ask a Question', 'Share an Experience', 'Find Support', 'Events', 'Groups', 'Success Stories']}
        />
      </div>

      <section className="mx-auto max-w-page px-4 pb-14 sm:px-6">
        <div className="grid gap-10 lg:grid-cols-[1fr_320px]">
          <div>
            <SectionHeader title="Latest Discussions" subtitle="Real conversations. Real support." viewAllHref="#" />
            <ul className="divide-y divide-slate-100 rounded-2xl border border-slate-100">
              {discussions.map((d) => (
                <li key={d.title} className="flex items-start gap-4 p-4">
                  <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-brand-100 text-sm font-semibold text-brand-700">
                    {d.author[0]}
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="text-xs text-slate-400">
                      {d.author} · {d.time}
                    </p>
                    <h3 className="mt-0.5 text-sm font-semibold text-slate-900">
                      {d.title}
                    </h3>
                    <span className="mt-2 inline-block rounded-full bg-brand-50 px-2.5 py-1 text-[11px] font-medium text-brand-700">
                      {d.tag}
                    </span>
                  </div>
                  <div className="flex shrink-0 flex-col items-end gap-1 text-xs text-slate-400">
                    <span className="flex items-center gap-1">
                      <MessageCircle className="h-3.5 w-3.5" /> {d.comments}
                    </span>
                    <span className="flex items-center gap-1">
                      <Heart className="h-3.5 w-3.5" /> {d.likes}
                    </span>
                  </div>
                </li>
              ))}
            </ul>

            <div className="mt-10">
              <SectionHeader title="Community Stories" subtitle="Inspiring stories from our community." viewAllHref="#" />
              <div className="grid gap-4 sm:grid-cols-3">
                {stories.map((s) => (
                  <figure
                    key={s.name}
                    className="rounded-2xl border border-slate-100 p-4"
                  >
                    <blockquote className="text-sm leading-relaxed text-slate-600">
                      &ldquo;{s.quote}&rdquo;
                    </blockquote>
                    <figcaption className="mt-3 text-xs font-semibold text-slate-900">
                      {s.name}
                      <span className="block font-normal text-slate-400">
                        {s.role}
                      </span>
                    </figcaption>
                  </figure>
                ))}
              </div>
            </div>
          </div>

          <aside className="space-y-5">
            <div className="rounded-2xl border border-slate-100 p-5">
              <h3 className="mb-3 flex items-center gap-2 text-sm font-bold text-slate-900">
                <Calendar className="h-4 w-4 text-brand-600" />
                Upcoming Community Events
              </h3>
              <ul className="space-y-3">
                {events.map((e) => (
                  <li key={e.title} className="text-sm">
                    <p className="font-medium text-slate-800">{e.title}</p>
                    <p className="text-xs text-slate-400">
                      {e.badge} · {e.date} · {e.time}
                    </p>
                  </li>
                ))}
              </ul>
            </div>

            <div className="rounded-2xl border border-slate-100 p-5">
              <h3 className="mb-3 flex items-center gap-2 text-sm font-bold text-slate-900">
                <GroupIcon className="h-4 w-4 text-brand-600" />
                Popular Groups
              </h3>
              <ul className="space-y-3">
                {groups.map((g) => (
                  <li key={g.name} className="flex items-center justify-between gap-2">
                    <span>
                      <span className="block text-sm font-medium text-slate-800">
                        {g.name}
                      </span>
                      <span className="text-xs text-slate-400">{g.members}</span>
                    </span>
                    <button
                      type="button"
                      className="shrink-0 rounded-full border border-brand-200 px-3 py-1 text-xs font-semibold text-brand-700"
                    >
                      Join
                    </button>
                  </li>
                ))}
              </ul>
            </div>
          </aside>
        </div>
      </section>

      <BottomCta
        heading="Be Part of a More Inclusive Tomorrow"
        subheading="Join our growing community and help create positive change."
        label="Join the Community"
      />
    </>
  );
}
