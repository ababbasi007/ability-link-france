import Link from 'next/link';

export function BrandMark({ className = 'h-9 w-9' }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 40 40"
      className={className}
      aria-hidden
      fill="none"
    >
      <circle cx="12" cy="14" r="4.2" fill="#0066FF" />
      <circle cx="28" cy="14" r="4.2" fill="#38BDF8" />
      <circle cx="20" cy="26" r="4.2" fill="#2563EB" />
      <path
        d="M15.2 16.2c1.4 1.2 3 1.9 4.8 1.9s3.4-.7 4.8-1.9"
        stroke="#0066FF"
        strokeWidth="1.8"
        strokeLinecap="round"
      />
      <path
        d="M14.5 24.2c1.6-1.4 3.4-2.2 5.5-2.2s3.9.8 5.5 2.2"
        stroke="#38BDF8"
        strokeWidth="1.8"
        strokeLinecap="round"
      />
    </svg>
  );
}

export function BrandLogo({
  href = '/',
  light = false,
}: {
  href?: string;
  light?: boolean;
}) {
  return (
    <Link href={href} className="flex items-center gap-2.5">
      <BrandMark />
      <span className="leading-tight">
        <span
          className={`block text-[17px] font-bold tracking-tight ${
            light ? 'text-white' : 'text-brand-900'
          }`}
        >
          Ability Link
        </span>
        <span
          className={`block text-[10px] font-medium tracking-wide ${
            light ? 'text-white/70' : 'text-slate-500'
          }`}
        >
          Access · Support · Opportunity
        </span>
      </span>
    </Link>
  );
}
