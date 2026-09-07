import { ArrowRight } from 'lucide-react';
import type { HowItWorksStep } from '@/lib/types';

export function HowItWorks({
  heading,
  steps,
}: {
  heading: string;
  steps: HowItWorksStep[];
}) {
  return (
    <section className="mx-auto max-w-page px-4 py-14 sm:px-6">
      <h2 className="mb-8 text-2xl font-bold text-slate-900">{heading}</h2>
      <div className="flex flex-col items-stretch gap-4 sm:flex-row sm:items-center">
        {steps.map((step, i) => (
          <div key={step.step} className="flex flex-1 items-center gap-4">
            <div className="flex flex-1 flex-col items-center gap-3 text-center">
              <span className="grid h-12 w-12 place-items-center rounded-full bg-brand-600 text-base font-bold text-white">
                {step.step}
              </span>
              <h3 className="text-sm font-semibold text-slate-900">
                {step.title}
              </h3>
              <p className="max-w-[160px] text-xs leading-relaxed text-slate-500">
                {step.description}
              </p>
            </div>
            {i < steps.length - 1 ? (
              <ArrowRight className="hidden h-5 w-5 shrink-0 text-brand-200 sm:block" />
            ) : null}
          </div>
        ))}
      </div>
    </section>
  );
}
