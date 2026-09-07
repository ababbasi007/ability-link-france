export interface Stat {
  value: string;
  label: string;
}

export function StatsBand({ stats }: { stats: Stat[] }) {
  return (
    <section className="border-y border-slate-100 bg-brand-50/60">
      <div className="mx-auto grid max-w-page grid-cols-2 gap-6 px-4 py-10 sm:px-6 md:grid-cols-4">
        {stats.map((s) => (
          <div key={s.label} className="text-center">
            <p className="text-3xl font-extrabold text-brand-700">{s.value}</p>
            <p className="mt-1 text-xs font-medium uppercase tracking-wide text-slate-500">
              {s.label}
            </p>
          </div>
        ))}
      </div>
    </section>
  );
}
