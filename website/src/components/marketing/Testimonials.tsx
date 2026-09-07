import { SectionHeader } from './SectionHeader';
import type { Testimonial } from '@/lib/types';

export function Testimonials({
  heading,
  items,
}: {
  heading: string;
  items: Testimonial[];
}) {
  return (
    <section className="bg-slate-50/70 py-14">
      <div className="mx-auto max-w-page px-4 sm:px-6">
        <SectionHeader title={heading} viewAllHref="#" />
        <div className="grid gap-5 sm:grid-cols-3">
          {items.map((t) => (
            <figure
              key={t.name}
              className="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm shadow-slate-100"
            >
              <blockquote className="text-sm leading-relaxed text-slate-600">
                &ldquo;{t.quote}&rdquo;
              </blockquote>
              <figcaption className="mt-4 flex items-center gap-3">
                <span className="grid h-9 w-9 place-items-center rounded-full bg-brand-100 text-xs font-semibold text-brand-700">
                  {t.name
                    .split(' ')
                    .map((p) => p[0])
                    .join('')}
                </span>
                <span>
                  <span className="block text-sm font-semibold text-slate-900">
                    {t.name}
                  </span>
                  <span className="block text-xs text-slate-400">
                    {t.location}
                  </span>
                </span>
              </figcaption>
            </figure>
          ))}
        </div>
      </div>
    </section>
  );
}
