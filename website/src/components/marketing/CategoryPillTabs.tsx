'use client';

import { useState } from 'react';

export function CategoryPillTabs({ tabs }: { tabs: string[] }) {
  const [active, setActive] = useState(0);

  return (
    <div className="-mt-14 mb-10 flex flex-wrap gap-2">
      {tabs.map((tab, i) => (
        <button
          key={tab}
          type="button"
          onClick={() => setActive(i)}
          className={`rounded-xl border px-4 py-3 text-sm font-semibold transition ${
            active === i
              ? 'border-brand-200 bg-brand-50 text-brand-700 shadow-sm'
              : 'border-slate-200 bg-white text-slate-600 hover:border-brand-200 hover:text-brand-700'
          }`}
        >
          {tab}
        </button>
      ))}
    </div>
  );
}
