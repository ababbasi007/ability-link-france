export function ComingSoon({
  eyebrow,
  title,
  description,
}: {
  eyebrow: string;
  title: string;
  description: string;
}) {
  return (
    <section className="mx-auto max-w-page px-4 py-24 text-center sm:px-6">
      <p className="text-xs font-bold uppercase tracking-[0.14em] text-brand-600">
        {eyebrow}
      </p>
      <h1 className="balance mx-auto mt-3 max-w-xl text-4xl font-extrabold text-slate-900">
        {title}
      </h1>
      <p className="mx-auto mt-4 max-w-md text-sm leading-relaxed text-slate-500">
        {description}
      </p>
    </section>
  );
}
