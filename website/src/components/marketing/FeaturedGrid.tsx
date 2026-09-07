import Image from 'next/image';
import { Star } from 'lucide-react';
import { SectionHeader } from './SectionHeader';
import type { FeaturedItem } from '@/lib/types';

export function FeaturedGrid({
  heading,
  subheading,
  items,
  columns = 3,
}: {
  heading: string;
  subheading?: string;
  items: FeaturedItem[];
  columns?: 3 | 4;
}) {
  return (
    <section className="bg-slate-50/70 py-14">
      <div className="mx-auto max-w-page px-4 sm:px-6">
        <SectionHeader title={heading} subtitle={subheading} viewAllHref="#" />
        <div
          className={`grid gap-5 ${
            columns === 4
              ? 'sm:grid-cols-2 lg:grid-cols-4'
              : 'sm:grid-cols-2 lg:grid-cols-3'
          }`}
        >
          {items.map((item) => (
            <article
              key={item.title}
              className="flex flex-col overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm shadow-slate-100 transition hover:-translate-y-0.5 hover:shadow-md"
            >
              <div className="relative aspect-[16/10] w-full">
                <Image
                  src={item.image}
                  alt=""
                  fill
                  sizes="(min-width: 1024px) 320px, 90vw"
                  className="object-cover"
                />
                {item.tag ? (
                  <span className="absolute left-3 top-3 rounded-full bg-white/95 px-2.5 py-1 text-[11px] font-semibold text-brand-700 shadow">
                    {item.tag}
                  </span>
                ) : null}
              </div>
              <div className="flex flex-1 flex-col gap-2 p-4">
                <p className="text-xs font-medium uppercase tracking-wide text-slate-400">
                  {item.meta}
                </p>
                <h3 className="text-base font-semibold leading-snug text-slate-900">
                  {item.title}
                </h3>
                {item.description ? (
                  <p className="line-clamp-2 text-sm text-slate-500">
                    {item.description}
                  </p>
                ) : null}
                {item.rating ? (
                  <span className="flex items-center gap-1 text-xs font-medium text-slate-500">
                    <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
                    {item.rating}
                  </span>
                ) : null}
                <div className="mt-auto pt-2">
                  <span className="inline-block rounded-full border border-brand-200 px-3.5 py-1.5 text-xs font-semibold text-brand-700 transition group-hover:bg-brand-50">
                    {item.cta}
                  </span>
                </div>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
