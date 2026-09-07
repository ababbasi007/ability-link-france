import Image from 'next/image';
import { Search } from 'lucide-react';
import { QuickLinksPanel } from './QuickLinksPanel';
import type { QuickLink } from '@/lib/types';

export function Hero({
  eyebrow,
  title,
  titleAccent,
  subtitle,
  image,
  handwrittenCaption,
  searchPlaceholder,
  trustBadges,
  quickLinks,
}: {
  eyebrow: string;
  title: string;
  titleAccent: string;
  subtitle: string;
  image: string;
  handwrittenCaption: string;
  searchPlaceholder: string;
  trustBadges: string[];
  quickLinks: QuickLink[];
}) {
  return (
    <section className="overflow-visible bg-gradient-to-b from-brand-50/70 to-white pb-24 pt-10 sm:pb-28">
      <div className="mx-auto grid max-w-page gap-10 px-4 sm:px-6 lg:grid-cols-[1.05fr_0.95fr] lg:items-center lg:gap-8">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.14em] text-brand-600">
            {eyebrow}
          </p>
          <h1 className="balance mt-3 text-4xl font-extrabold leading-[1.08] text-slate-900 sm:text-5xl">
            {title}
            <br />
            <span className="text-brand-600">{titleAccent}</span>
          </h1>
          <p className="mt-5 max-w-xl text-base leading-relaxed text-slate-500">
            {subtitle}
          </p>

          <form className="mt-7 flex max-w-xl gap-2 rounded-full border border-slate-200 bg-white p-1.5 shadow-sm">
            <div className="flex flex-1 items-center gap-2 pl-3">
              <Search className="h-4 w-4 shrink-0 text-slate-400" />
              <input
                type="text"
                placeholder={searchPlaceholder}
                className="w-full min-w-0 py-2 text-sm outline-none placeholder:text-slate-400"
              />
            </div>
            <button
              type="submit"
              className="shrink-0 rounded-full bg-brand-600 px-5 py-2 text-sm font-semibold text-white transition hover:bg-brand-700"
            >
              Search
            </button>
          </form>

          <div className="mt-5 flex flex-wrap gap-2">
            {trustBadges.map((badge) => (
              <span
                key={badge}
                className="rounded-full border border-slate-200 bg-white px-3.5 py-1.5 text-xs font-medium text-slate-600"
              >
                {badge}
              </span>
            ))}
          </div>
        </div>

        <div className="relative mx-auto w-full max-w-md lg:mx-0">
          <p className="font-hand absolute -top-8 right-2 z-10 -rotate-3 text-xl font-semibold leading-tight text-brand-700 sm:right-4 sm:text-2xl">
            {handwrittenCaption.split('\n').map((line, i) => (
              <span key={i} className="block">
                {line}
              </span>
            ))}
          </p>
          <div className="relative aspect-[4/3] w-full overflow-hidden rounded-3xl shadow-xl shadow-brand-900/10">
            <Image
              src={image}
              alt=""
              fill
              sizes="(min-width: 1024px) 460px, 90vw"
              className="object-cover"
              priority
            />
          </div>
          <div className="absolute -bottom-10 -right-4 hidden sm:block">
            <QuickLinksPanel links={quickLinks} />
          </div>
        </div>
      </div>
    </section>
  );
}
