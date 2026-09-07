'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Search, ChevronDown, Globe } from 'lucide-react';
import { BrandLogo } from '@/components/BrandLogo';
import { mainNav } from '@/data/navigation';

export function Navbar({ variant = 'guest' }: { variant?: 'guest' | 'user' }) {
  const pathname = usePathname();

  return (
    <header className="sticky top-0 z-40">
      <div className="bg-brand-900 text-[12px] text-white/90">
        <div className="mx-auto flex h-9 max-w-page items-center justify-between gap-4 px-4 sm:px-6">
          <p className="truncate font-medium tracking-wide">
            Empowering People. Building an Inclusive World.
          </p>
          <div className="flex shrink-0 items-center gap-5">
            <Link
              href="/legal/accessibility"
              className="hidden transition hover:text-white sm:inline"
            >
              Accessibility Tools
            </Link>
            <Link
              href="/help-center"
              className="hidden transition hover:text-white sm:inline"
            >
              Help &amp; Support
            </Link>
            <button
              type="button"
              className="inline-flex items-center gap-1.5 rounded-md border border-white/20 px-2 py-0.5 text-[11px] font-semibold text-white transition hover:bg-white/10"
            >
              <Globe className="h-3 w-3" />
              EN
              <ChevronDown className="h-3 w-3 opacity-70" />
            </button>
          </div>
        </div>
      </div>

      <div className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex h-[68px] max-w-page items-center justify-between gap-6 px-4 sm:px-6">
          <BrandLogo />

          <nav className="hidden items-center gap-6 xl:flex">
            {mainNav.map((item) => {
              const active =
                item.href === '/'
                  ? pathname === '/'
                  : pathname.startsWith(item.href);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`inline-flex items-center gap-1 text-[13.5px] font-medium transition ${
                    active
                      ? 'text-brand-600'
                      : 'text-slate-600 hover:text-brand-700'
                  }`}
                >
                  {item.label}
                  {'dropdown' in item && item.dropdown ? (
                    <ChevronDown className="h-3.5 w-3.5 opacity-60" />
                  ) : null}
                </Link>
              );
            })}
          </nav>

          <div className="flex items-center gap-2.5">
            <button
              type="button"
              aria-label="Search"
              className="grid h-9 w-9 place-items-center rounded-full text-slate-500 transition hover:bg-slate-100 hover:text-brand-700"
            >
              <Search className="h-[18px] w-[18px]" />
            </button>

            {variant === 'guest' ? (
              <div className="hidden items-center gap-2 sm:flex">
                <Link
                  href="/login"
                  className="rounded-lg border border-brand-600 px-4 py-1.5 text-sm font-semibold text-brand-600 transition hover:bg-brand-50"
                >
                  Log In
                </Link>
                <Link
                  href="/signup"
                  className="rounded-lg bg-brand-600 px-4 py-1.5 text-sm font-semibold text-white shadow-sm transition hover:bg-brand-700"
                >
                  Sign Up
                </Link>
              </div>
            ) : null}
          </div>
        </div>
      </div>
    </header>
  );
}
