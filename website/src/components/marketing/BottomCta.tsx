export function BottomCta({
  heading,
  subheading,
  label,
}: {
  heading: string;
  subheading: string;
  label: string;
}) {
  return (
    <section className="mx-auto max-w-page px-4 pb-16 sm:px-6">
      <div className="flex flex-col items-start justify-between gap-5 rounded-3xl bg-brand-600 p-8 sm:flex-row sm:items-center sm:p-10">
        <div>
          <h2 className="balance text-xl font-bold text-white sm:text-2xl">
            {heading}
          </h2>
          <p className="mt-1.5 max-w-lg text-sm text-brand-100">
            {subheading}
          </p>
        </div>
        <button
          type="button"
          className="shrink-0 rounded-full bg-white px-6 py-3 text-sm font-semibold text-brand-700 transition hover:bg-brand-50"
        >
          {label}
        </button>
      </div>
    </section>
  );
}
