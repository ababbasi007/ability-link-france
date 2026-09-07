import Image from 'next/image';
import Link from 'next/link';
import {
  MapPin,
  Accessibility,
  Stethoscope,
  GraduationCap,
  Briefcase,
  Plane,
  Bus,
  Users,
  Cpu,
  ShieldCheck,
  Scale,
  HeartHandshake,
  Wrench,
  Bot,
  MoreHorizontal,
  ArrowRight,
  Sprout,
  Heart,
  Quote,
} from 'lucide-react';

const SERVICES = [
  {
    icon: MapPin,
    title: 'Ability Map',
    desc: 'Find accessible places near you.',
    href: '/ability-map',
    bg: 'bg-sky-100',
    color: 'text-sky-600',
  },
  {
    icon: Accessibility,
    title: 'Tele Rehab',
    desc: 'Online rehabilitation sessions.',
    href: '/telerehab',
    bg: 'bg-violet-100',
    color: 'text-violet-600',
  },
  {
    icon: Stethoscope,
    title: 'Tele Health',
    desc: 'Consult doctors from home.',
    href: '/telehealth',
    bg: 'bg-rose-100',
    color: 'text-rose-600',
  },
  {
    icon: GraduationCap,
    title: 'Accessible Education',
    desc: 'Learn without barriers.',
    href: '/education',
    bg: 'bg-emerald-100',
    color: 'text-emerald-600',
  },
  {
    icon: Briefcase,
    title: 'Jobs',
    desc: 'Inclusive career opportunities.',
    href: '/jobs',
    bg: 'bg-amber-100',
    color: 'text-amber-600',
  },
  {
    icon: Plane,
    title: 'Accessible Tourism',
    desc: 'Travel with confidence.',
    href: '/accessible-tourism',
    bg: 'bg-pink-100',
    color: 'text-pink-600',
  },
  {
    icon: Bus,
    title: 'Accessible Transport',
    desc: 'Mobility made easier.',
    href: '/accessible-transport',
    bg: 'bg-teal-100',
    color: 'text-teal-600',
  },
  {
    icon: Users,
    title: 'Community',
    desc: 'Connect, share and grow.',
    href: '/community',
    bg: 'bg-fuchsia-100',
    color: 'text-fuchsia-600',
  },
  {
    icon: Cpu,
    title: 'Assistive Technology',
    desc: 'Tools that empower daily life.',
    href: '/assistive-technology',
    bg: 'bg-indigo-100',
    color: 'text-indigo-600',
  },
  {
    icon: ShieldCheck,
    title: 'Benefits',
    desc: 'Discover support you can claim.',
    href: '/benefits',
    bg: 'bg-lime-100',
    color: 'text-lime-700',
  },
  {
    icon: Scale,
    title: 'Rights & Legal',
    desc: 'Know and protect your rights.',
    href: '/rights-legal',
    bg: 'bg-purple-100',
    color: 'text-purple-600',
  },
  {
    icon: HeartHandshake,
    title: 'Caregiver Support',
    desc: 'Guidance for those who care.',
    href: '/caregiver-support',
    bg: 'bg-orange-100',
    color: 'text-orange-600',
  },
  {
    icon: Wrench,
    title: 'Services',
    desc: 'Book trusted local support.',
    href: '/services',
    bg: 'bg-blue-100',
    color: 'text-blue-600',
  },
  {
    icon: Bot,
    title: 'AI Assistant',
    desc: 'Get answers when you need them.',
    href: '/ai-assistant',
    bg: 'bg-cyan-100',
    color: 'text-cyan-600',
  },
  {
    icon: MoreHorizontal,
    title: 'More Coming Soon',
    desc: 'New services are on the way.',
    href: '/services',
    bg: 'bg-slate-100',
    color: 'text-slate-500',
  },
] as const;

const TESTIMONIALS = [
  {
    quote:
      'Ability Link helped me find accessible places in my city and connected me with a supportive community. I finally feel independent again.',
    name: 'Ali Raza',
    location: 'Lahore, Pakistan',
    image:
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&h=120&fit=crop&q=80',
  },
  {
    quote:
      'As a caregiver, the resources and tele rehab sessions made a real difference for my mother. Everything we needed was in one place.',
    name: 'Sara Khan',
    location: 'Islamabad, Pakistan',
    image:
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&h=120&fit=crop&q=80',
  },
  {
    quote:
      'I found a remote job through Ability Link that respects my needs. Equal opportunity finally feels real — not just a slogan.',
    name: 'Hassan Ahmed',
    location: 'Karachi, Pakistan',
    image:
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=120&h=120&fit=crop&q=80',
  },
];

const PARTNERS = [
  'UNICEF',
  'WHO',
  'UNESCO',
  'World Bank',
  'HelpAge',
  'CBM',
];

const NEWS = [
  {
    tag: 'News',
    tagClass: 'bg-brand-600 text-white',
    title: 'New Accessibility Features Launch Across Ability Map',
    excerpt:
      'Discover how updated filters and community reviews make finding accessible places easier than ever.',
    date: 'Sep 2, 2026',
    image:
      'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?w=640&h=400&fit=crop&q=80',
  },
  {
    tag: 'Guide',
    tagClass: 'bg-emerald-500 text-white',
    title: 'A Practical Guide to Inclusive Remote Work',
    excerpt:
      'Tips for job seekers and employers building workplaces that work for every ability.',
    date: 'Aug 28, 2026',
    image:
      'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=640&h=400&fit=crop&q=80',
  },
  {
    tag: 'Article',
    tagClass: 'bg-violet-500 text-white',
    title: 'Why Community Support Changes Recovery Outcomes',
    excerpt:
      'Stories from members who found strength, friendship and practical help through Ability Link.',
    date: 'Aug 20, 2026',
    image:
      'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=640&h=400&fit=crop&q=80',
  },
];

export default function HomePage() {
  return (
    <>
      {/* Hero */}
      <section className="relative overflow-hidden bg-[#f7f9fc]">
        <div
          className="pointer-events-none absolute inset-0 opacity-40 dot-pattern"
          aria-hidden
        />
        <div className="relative mx-auto grid max-w-page items-center gap-12 px-4 py-14 sm:px-6 lg:grid-cols-[1.05fr_0.95fr] lg:gap-10 lg:py-16">
          <div>
            <h1 className="balance text-[2.35rem] font-extrabold leading-[1.12] tracking-tight text-brand-900 sm:text-5xl">
              A More Inclusive Tomorrow,{' '}
              <span className="text-brand-600">Together.</span>
            </h1>
            <p className="mt-5 max-w-xl text-[15px] leading-relaxed text-slate-500 sm:text-base">
              Ability Link connects people with disabilities and senior citizens
              to the support, services and opportunities they need to live
              independently and with dignity.
            </p>

            <div className="mt-8 flex flex-wrap items-center gap-3">
              <Link
                href="/signup"
                className="inline-flex items-center gap-2 rounded-full bg-brand-600 px-6 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-brand-700"
              >
                Join Ability Link
                <ArrowRight className="h-4 w-4" />
              </Link>
              <Link
                href="/services"
                className="inline-flex items-center gap-2 rounded-full border border-brand-600 bg-white px-6 py-2.5 text-sm font-semibold text-brand-600 transition hover:bg-brand-50"
              >
                Explore Services
                <ArrowRight className="h-4 w-4" />
              </Link>
            </div>

            <div className="mt-9 flex flex-wrap gap-x-7 gap-y-4">
              <div className="flex items-center gap-2.5">
                <span className="grid h-9 w-9 place-items-center rounded-full bg-brand-100 text-brand-600">
                  <Users className="h-4 w-4" />
                </span>
                <span className="text-sm font-semibold text-slate-700">
                  Greater Independence
                </span>
              </div>
              <div className="flex items-center gap-2.5">
                <span className="grid h-9 w-9 place-items-center rounded-full bg-teal-100 text-teal-600">
                  <Heart className="h-4 w-4" />
                </span>
                <span className="text-sm font-semibold text-slate-700">
                  Stronger Communities
                </span>
              </div>
              <div className="flex items-center gap-2.5">
                <span className="grid h-9 w-9 place-items-center rounded-full bg-violet-100 text-violet-600">
                  <Sprout className="h-4 w-4" />
                </span>
                <span className="text-sm font-semibold text-slate-700">
                  More Opportunities
                </span>
              </div>
            </div>
          </div>

          <div className="relative mx-auto w-full max-w-[440px] lg:mx-0 lg:justify-self-end">
            <div
              className="pointer-events-none absolute -inset-3 rounded-full border border-slate-200/80"
              aria-hidden
            />
            <div
              className="pointer-events-none absolute -left-2 top-8 h-[72%] w-[72%] rounded-full border border-slate-200/70"
              aria-hidden
            />
            <div className="relative aspect-square w-full overflow-hidden rounded-full shadow-[0_20px_50px_rgba(10,29,55,0.18)] ring-[10px] ring-white">
              <Image
                src="https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=900&h=900&fit=crop&q=80"
                alt="Friends including a wheelchair user smiling outdoors"
                fill
                priority
                sizes="440px"
                className="object-cover object-[center_20%]"
              />
            </div>
            <div className="absolute bottom-6 left-0 z-10 flex max-w-[240px] items-center gap-3 rounded-2xl bg-white px-3.5 py-3 shadow-card sm:-left-6">
              <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-brand-100 text-brand-600">
                <Accessibility className="h-5 w-5" />
              </span>
              <p className="text-[13px] font-semibold leading-snug text-slate-800">
                Accessibility Creates Opportunities
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Services */}
      <section className="bg-white py-14 sm:py-16">
        <div className="mx-auto max-w-page px-4 sm:px-6">
          <div className="mb-8 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <h2 className="text-2xl font-extrabold tracking-tight text-brand-900 sm:text-[1.75rem]">
                Everything You Need. All in One Place.
              </h2>
            </div>
            <Link
              href="/services"
              className="inline-flex items-center gap-1.5 text-sm font-semibold text-brand-600 hover:text-brand-700"
            >
              View All Services
              <ArrowRight className="h-4 w-4" />
            </Link>
          </div>

          <div className="grid gap-3.5 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-5">
            {SERVICES.map((s) => {
              const Icon = s.icon;
              return (
                <Link
                  key={s.title}
                  href={s.href}
                  className="group flex flex-col rounded-2xl border border-slate-200 bg-white p-4 shadow-sm transition hover:border-brand-200 hover:shadow-card"
                >
                  <span
                    className={`mb-3 grid h-10 w-10 place-items-center rounded-xl ${s.bg} ${s.color}`}
                  >
                    <Icon className="h-5 w-5" strokeWidth={2} />
                  </span>
                  <strong className="text-[14px] font-bold text-slate-900 group-hover:text-brand-700">
                    {s.title}
                  </strong>
                  <span className="mt-1 text-[12.5px] leading-snug text-slate-500">
                    {s.desc}
                  </span>
                </Link>
              );
            })}
          </div>
        </div>
      </section>

      {/* Stats */}
      <section className="bg-brand-600">
        <div className="mx-auto flex max-w-page flex-col gap-8 px-4 py-10 sm:px-6 lg:flex-row lg:items-center lg:justify-between">
          <div className="grid flex-1 grid-cols-2 gap-8 md:grid-cols-4">
            {[
              { value: '10,000+', label: 'Registered Users' },
              { value: '500+', label: 'Service Providers' },
              { value: '5,000+', label: 'Bookings Completed' },
              { value: '20+', label: 'Partner Organizations' },
            ].map((stat) => (
              <div key={stat.label} className="text-center text-white lg:text-left">
                <div className="mx-auto mb-2 grid h-9 w-9 place-items-center rounded-lg bg-white/15 lg:mx-0">
                  <Users className="h-4 w-4" />
                </div>
                <p className="text-2xl font-extrabold tracking-tight">{stat.value}</p>
                <p className="mt-0.5 text-sm text-white/85">{stat.label}</p>
              </div>
            ))}
          </div>
          <p className="shrink-0 text-center font-hand text-3xl font-semibold leading-none text-white/95 lg:text-right lg:text-4xl">
            Inclusion Changes Lives
          </p>
        </div>
      </section>

      {/* Testimonials */}
      <section className="bg-[#f7f9fc] py-14 sm:py-16">
        <div className="mx-auto max-w-page px-4 sm:px-6">
          <div className="mb-8 flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <h2 className="text-2xl font-extrabold tracking-tight text-brand-900 sm:text-[1.75rem]">
                Real People. Real Impact.
              </h2>
              <p className="mt-1 text-sm text-slate-500">
                Stories from our community
              </p>
            </div>
            <Link
              href="/community"
              className="inline-flex items-center gap-1.5 text-sm font-semibold text-brand-600 hover:text-brand-700"
            >
              View All Stories
              <ArrowRight className="h-4 w-4" />
            </Link>
          </div>

          <div className="grid gap-5 md:grid-cols-3">
            {TESTIMONIALS.map((t) => (
              <article
                key={t.name}
                className="flex flex-col rounded-2xl border border-brand-100 bg-[#eef5ff] p-6 shadow-sm"
              >
                <Quote className="h-7 w-7 text-brand-300" />
                <p className="mt-4 flex-1 text-[14px] leading-relaxed text-slate-700">
                  {t.quote}
                </p>
                <div className="mt-6 flex items-center gap-3 border-t border-brand-100/80 pt-4">
                  <Image
                    src={t.image}
                    alt=""
                    width={40}
                    height={40}
                    className="h-10 w-10 rounded-full object-cover"
                  />
                  <div>
                    <p className="text-sm font-bold text-slate-900">{t.name}</p>
                    <p className="text-xs text-slate-500">{t.location}</p>
                  </div>
                </div>
              </article>
            ))}
          </div>
        </div>
      </section>

      {/* Partners */}
      <section className="bg-white py-12">
        <div className="mx-auto max-w-page px-4 text-center sm:px-6">
          <h2 className="text-xl font-extrabold tracking-tight text-brand-900 sm:text-2xl">
            Our Partners
          </h2>
          <p className="mt-1 text-sm text-slate-500">
            Working together for a more inclusive world.
          </p>
          <div className="mt-8 flex flex-wrap items-center justify-center gap-x-10 gap-y-5">
            {PARTNERS.map((name) => (
              <span
                key={name}
                className="text-sm font-bold tracking-wide text-slate-400 sm:text-base"
              >
                {name}
              </span>
            ))}
          </div>
        </div>
      </section>

      {/* News */}
      <section className="bg-[#f7f9fc] py-14 sm:py-16">
        <div className="mx-auto max-w-page px-4 sm:px-6">
          <div className="mb-8 flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
            <h2 className="text-2xl font-extrabold tracking-tight text-brand-900 sm:text-[1.75rem]">
              Latest News &amp; Resources
            </h2>
            <Link
              href="/resources"
              className="inline-flex items-center gap-1.5 text-sm font-semibold text-brand-600 hover:text-brand-700"
            >
              View All Articles
              <ArrowRight className="h-4 w-4" />
            </Link>
          </div>

          <div className="grid gap-5 md:grid-cols-3">
            {NEWS.map((n) => (
              <article
                key={n.title}
                className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm"
              >
                <div className="relative aspect-[16/10]">
                  <Image
                    src={n.image}
                    alt=""
                    fill
                    sizes="(min-width: 768px) 33vw, 100vw"
                    className="object-cover"
                  />
                  <span
                    className={`absolute left-3 top-3 rounded-md px-2.5 py-1 text-[11px] font-bold uppercase tracking-wide ${n.tagClass}`}
                  >
                    {n.tag}
                  </span>
                </div>
                <div className="p-5">
                  <h3 className="text-[15px] font-bold leading-snug text-slate-900">
                    {n.title}
                  </h3>
                  <p className="mt-2 text-[13px] leading-relaxed text-slate-500">
                    {n.excerpt}
                  </p>
                  <div className="mt-4 flex items-center justify-between gap-3">
                    <span className="text-xs text-slate-400">{n.date}</span>
                    <Link
                      href="/resources"
                      className="inline-flex items-center gap-1 text-sm font-semibold text-brand-600"
                    >
                      Read More
                      <ArrowRight className="h-3.5 w-3.5" />
                    </Link>
                  </div>
                </div>
              </article>
            ))}
          </div>
        </div>
      </section>

      {/* Newsletter */}
      <section className="bg-white py-10 sm:py-12">
        <div className="mx-auto max-w-page px-4 sm:px-6">
          <div className="flex flex-col items-center gap-6 rounded-2xl bg-[#e8f1ff] px-6 py-8 sm:flex-row sm:justify-between sm:px-10">
            <div className="flex items-center gap-4 text-center sm:text-left">
              <span className="hidden h-14 w-14 shrink-0 place-items-center rounded-2xl bg-white text-brand-600 shadow-sm sm:grid">
                <svg
                  viewBox="0 0 24 24"
                  className="h-7 w-7"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.75"
                >
                  <path d="M4 6h16v12H4z" />
                  <path d="m4 7 8 6 8-6" />
                </svg>
              </span>
              <div>
                <h2 className="text-xl font-extrabold text-brand-900">
                  Stay Updated!
                </h2>
                <p className="mt-1 max-w-md text-sm text-slate-600">
                  Subscribe to our newsletter for news, resources and inclusive
                  opportunities.
                </p>
              </div>
            </div>
            <form className="flex w-full max-w-md gap-2">
              <input
                type="email"
                required
                placeholder="Enter your email address"
                className="min-w-0 flex-1 rounded-lg border border-slate-200 bg-white px-4 py-2.5 text-sm outline-none ring-brand-500 focus:ring-2"
              />
              <button
                type="submit"
                className="shrink-0 rounded-lg bg-brand-600 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-brand-700"
              >
                Subscribe
              </button>
            </form>
          </div>
        </div>
      </section>
    </>
  );
}
