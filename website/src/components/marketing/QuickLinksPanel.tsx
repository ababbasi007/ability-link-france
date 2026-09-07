import type { QuickLink } from '@/lib/types';

export function QuickLinksPanel({ links }: { links: QuickLink[] }) {
  return (
    <div className="w-full max-w-[260px] rounded-2xl border border-slate-100 bg-white p-4 shadow-lg shadow-slate-200/60">
      <ul className="space-y-3.5">
        {links.map(({ icon: Icon, label }) => (
          <li key={label} className="flex items-center gap-3">
            <span className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-brand-50 text-brand-600">
              <Icon className="h-4 w-4" />
            </span>
            <span className="text-sm font-medium text-slate-700">{label}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}
