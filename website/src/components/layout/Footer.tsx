import Link from 'next/link';
import { Globe, ChevronDown } from 'lucide-react';
import { BrandLogo } from '@/components/BrandLogo';
import {
  footerQuickLinks,
  footerResources,
  footerServices,
  footerSupport,
  socialLinks,
} from '@/data/navigation';

function FooterCol({
  heading,
  links,
}: {
  heading: string;
  links: { href: string; label: string }[];
}) {
  return (
    <div>
      <h3 className="text-sm font-semibold text-white">{heading}</h3>
      <ul className="mt-4 space-y-2.5">
        {links.map((l) => (
          <li key={l.label}>
            <Link
              href={l.href}
              className="text-sm text-white/65 transition hover:text-white"
            >
              {l.label}
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}

export function Footer() {
  return (
    <footer className="bg-brand-900 text-white">
      <div className="mx-auto max-w-page px-4 py-14 sm:px-6">
        <div className="grid gap-10 lg:grid-cols-[1.35fr_1fr_1fr_1fr_1fr_1.15fr]">
          <div>
            <BrandLogo light />
            <p className="mt-4 max-w-[240px] text-sm leading-relaxed text-white/65">
              Connecting people with disabilities and senior citizens to a more
              inclusive world.
            </p>
            <div className="mt-5 flex gap-2">
              {socialLinks.map((s) => (
                <a
                  key={s.label}
                  href={s.href}
                  aria-label={s.label}
                  className="grid h-8 w-8 place-items-center rounded-full bg-white/10 text-[11px] font-semibold text-white/80 transition hover:bg-brand-600 hover:text-white"
                >
                  {s.label === 'Facebook'
                    ? 'f'
                    : s.label === 'X'
                      ? '𝕏'
                      : s.label[0]}
                </a>
              ))}
            </div>
          </div>

          <FooterCol heading="Quick Links" links={footerQuickLinks} />
          <FooterCol heading="Services" links={footerServices} />
          <FooterCol heading="Resources" links={footerResources} />
          <FooterCol heading="Support" links={footerSupport} />

          <div>
            <h3 className="text-sm font-semibold text-white">Get the App</h3>
            <p className="mt-4 text-sm text-white/65">
              Download Ability Link on your phone.
            </p>
            <div className="mt-4 space-y-2.5">
              <a
                href="#"
                className="flex items-center gap-3 rounded-lg border border-white/15 bg-black/30 px-3 py-2 transition hover:border-white/30"
              >
                <span className="text-2xl leading-none" aria-hidden>
                  ▶
                </span>
                <span className="leading-tight">
                  <span className="block text-[10px] text-white/60">
                    GET IT ON
                  </span>
                  <span className="block text-sm font-semibold">Google Play</span>
                </span>
              </a>
              <a
                href="#"
                className="flex items-center gap-3 rounded-lg border border-white/15 bg-black/30 px-3 py-2 transition hover:border-white/30"
              >
                <span className="text-xl leading-none" aria-hidden>
                  
                </span>
                <span className="leading-tight">
                  <span className="block text-[10px] text-white/60">
                    Download on the
                  </span>
                  <span className="block text-sm font-semibold">App Store</span>
                </span>
              </a>
            </div>
          </div>
        </div>

        <div className="mt-12 flex flex-col gap-3 border-t border-white/10 pt-6 text-xs text-white/55 sm:flex-row sm:items-center sm:justify-between">
          <p>&copy; 2026 Ability Link. All rights reserved.</p>
          <div className="flex flex-wrap items-center gap-x-4 gap-y-2">
            <Link href="/legal/privacy" className="hover:text-white">
              Privacy Policy
            </Link>
            <Link href="/legal/terms" className="hover:text-white">
              Terms of Service
            </Link>
            <Link href="/legal/cookies" className="hover:text-white">
              Cookies Policy
            </Link>
            <button
              type="button"
              className="inline-flex items-center gap-1.5 rounded-md border border-white/15 px-2 py-1 font-medium text-white/80"
            >
              <Globe className="h-3 w-3" />
              EN
              <ChevronDown className="h-3 w-3" />
            </button>
          </div>
        </div>
      </div>
    </footer>
  );
}
