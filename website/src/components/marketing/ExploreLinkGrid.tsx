import Link from 'next/link';
import { SectionHeader } from './SectionHeader';
import type { BadgeColor } from '@/lib/types';
import type { LucideIcon } from 'lucide-react';

const badgeStyles: Record<BadgeColor, string> = {
  blue: 'bg-sky-100 text-sky-600',
  purple: 'bg-purple-100 text-purple-600',
  rose: 'bg-rose-100 text-rose-600',
  emerald: 'bg-emerald-100 text-emerald-600',
  amber: 'bg-amber-100 text-amber-600',
  sky: 'bg-cyan-100 text-cyan-600',
  violet: 'bg-violet-100 text-violet-600',
  slate: 'bg-slate-100 text-slate-600',
};

export interface ExploreLink {
  icon: LucideIcon;
  label: string;
  href: string;
  color: BadgeColor;
}

export function ExploreLinkGrid({
  heading,
  subheading,
  items,
}: {
  heading: string;
  subheading?: string;
  items: ExploreLink[];
}) {
  return (
    <section className="mx-auto max-w-page px-4 py-14 sm:px-6">
      <SectionHeader title={heading} subtitle={subheading} />
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
        {items.map(({ icon: Icon, label, href, color }) => (
          <Link
            key={label}
            href={href}
            className="flex flex-col items-center gap-2.5 rounded-2xl border border-slate-100 bg-white px-4 py-6 text-center shadow-sm shadow-slate-100 transition hover:-translate-y-0.5 hover:border-brand-200 hover:shadow-md"
          >
            <span
              className={`grid h-12 w-12 place-items-center rounded-full ${badgeStyles[color]}`}
            >
              <Icon className="h-5 w-5" />
            </span>
            <span className="text-sm font-semibold text-slate-800">
              {label}
            </span>
          </Link>
        ))}
      </div>
    </section>
  );
}
