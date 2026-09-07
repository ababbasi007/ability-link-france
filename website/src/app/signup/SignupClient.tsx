'use client';

import { useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import {
  User,
  Building2,
  Mail,
  Lock,
  Eye,
  Users,
  Heart,
  BookOpen,
  Star,
  Plane,
  GraduationCap,
  Briefcase,
  HeartPulse,
  Cpu,
  Scale,
  MoreHorizontal,
} from 'lucide-react';

const interests = [
  { icon: Plane, label: 'Accessible Tourism' },
  { icon: GraduationCap, label: 'Education' },
  { icon: Briefcase, label: 'Jobs & Employment' },
  { icon: HeartPulse, label: 'Health & Rehabilitation' },
  { icon: Cpu, label: 'Assistive Technology' },
  { icon: Users, label: 'Community' },
  { icon: Scale, label: 'Rights & Legal' },
  { icon: Heart, label: 'Caregiver Support' },
  { icon: MoreHorizontal, label: 'Other' },
];

export function SignupClient() {
  const [accountType, setAccountType] = useState<'individual' | 'organization'>('individual');
  const [selected, setSelected] = useState<string[]>([]);

  const toggle = (label: string) => {
    setSelected((s) =>
      s.includes(label) ? s.filter((x) => x !== label) : [...s, label],
    );
  };

  return (
    <section className="mx-auto grid max-w-page gap-10 px-4 py-10 sm:px-6 lg:grid-cols-2 lg:items-center lg:gap-14">
      <div>
        <h1 className="balance text-3xl font-extrabold leading-tight text-slate-900 sm:text-4xl">
          Join Ability Link
          <br />
          Be Part of a More
          <br />
          <span className="text-brand-600">Inclusive Tomorrow</span>
        </h1>
        <p className="mt-4 max-w-md text-sm leading-relaxed text-slate-500">
          Create your free account and access services, programs, resources
          and a supportive community for a brighter, more inclusive world.
        </p>

        <ul className="mt-6 space-y-4">
          {[
            { icon: Users, title: 'Access Opportunities', description: 'Discover services, jobs and programs' },
            { icon: Heart, title: 'Connect with People', description: 'Join a supportive community' },
            { icon: BookOpen, title: 'Learn and Grow', description: 'Access resources and education' },
            { icon: Star, title: 'Make a Real Impact', description: 'Be part of positive change' },
          ].map(({ icon: Icon, title, description }) => (
            <li key={title} className="flex items-start gap-3">
              <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-brand-100 text-brand-600">
                <Icon className="h-4 w-4" />
              </span>
              <span>
                <span className="block text-sm font-semibold text-slate-900">
                  {title}
                </span>
                <span className="block text-xs text-slate-500">
                  {description}
                </span>
              </span>
            </li>
          ))}
        </ul>

        <div className="relative mt-8 hidden overflow-hidden rounded-2xl sm:block">
          <div className="relative aspect-[16/10] w-full">
            <Image
              src="https://picsum.photos/seed/signup/700/440"
              alt=""
              fill
              sizes="500px"
              className="object-cover"
            />
          </div>
          <p className="absolute bottom-4 left-4 right-4 rounded-xl bg-black/60 px-4 py-3 text-sm italic text-white">
            &ldquo;A stronger, more inclusive world starts with you.&rdquo;
          </p>
        </div>
      </div>

      <div className="rounded-3xl border border-slate-100 p-6 shadow-lg shadow-slate-200/60 sm:p-8">
        <h2 className="text-xl font-bold text-slate-900">
          Create Your Account
        </h2>
        <p className="mt-1 text-sm text-slate-500">
          Join Ability Link and be part of a global community.
        </p>

        <div className="mt-5 grid grid-cols-2 gap-2 rounded-xl border border-slate-200 p-1">
          <button
            type="button"
            onClick={() => setAccountType('individual')}
            className={`flex items-center justify-center gap-2 rounded-lg py-2.5 text-sm font-semibold transition ${
              accountType === 'individual'
                ? 'bg-brand-50 text-brand-700'
                : 'text-slate-500'
            }`}
          >
            <User className="h-4 w-4" />
            Individual
          </button>
          <button
            type="button"
            onClick={() => setAccountType('organization')}
            className={`flex items-center justify-center gap-2 rounded-lg py-2.5 text-sm font-semibold transition ${
              accountType === 'organization'
                ? 'bg-brand-50 text-brand-700'
                : 'text-slate-500'
            }`}
          >
            <Building2 className="h-4 w-4" />
            Organization
          </button>
        </div>

        <form className="mt-5 space-y-4" onSubmit={(e) => e.preventDefault()}>
          <div>
            <label className="mb-1 block text-xs font-semibold text-slate-700">
              Full Name *
            </label>
            <div className="flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2.5">
              <User className="h-4 w-4 text-slate-400" />
              <input
                type="text"
                placeholder="Enter your full name"
                className="w-full min-w-0 text-sm outline-none"
              />
            </div>
          </div>

          <div>
            <label className="mb-1 block text-xs font-semibold text-slate-700">
              Email Address *
            </label>
            <div className="flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2.5">
              <Mail className="h-4 w-4 text-slate-400" />
              <input
                type="email"
                placeholder="you@example.com"
                className="w-full min-w-0 text-sm outline-none"
              />
            </div>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <label className="mb-1 block text-xs font-semibold text-slate-700">
                Password *
              </label>
              <div className="flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2.5">
                <Lock className="h-4 w-4 text-slate-400" />
                <input
                  type="password"
                  placeholder="Create a password"
                  className="w-full min-w-0 text-sm outline-none"
                />
                <Eye className="h-4 w-4 shrink-0 text-slate-400" />
              </div>
            </div>
            <div>
              <label className="mb-1 block text-xs font-semibold text-slate-700">
                Confirm Password *
              </label>
              <div className="flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2.5">
                <Lock className="h-4 w-4 text-slate-400" />
                <input
                  type="password"
                  placeholder="Confirm your password"
                  className="w-full min-w-0 text-sm outline-none"
                />
                <Eye className="h-4 w-4 shrink-0 text-slate-400" />
              </div>
            </div>
          </div>

          <div>
            <label className="mb-2 block text-xs font-semibold text-slate-700">
              Areas of Interest (select one or more)
            </label>
            <div className="flex flex-wrap gap-2">
              {interests.map(({ icon: Icon, label }) => (
                <button
                  key={label}
                  type="button"
                  onClick={() => toggle(label)}
                  className={`flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition ${
                    selected.includes(label)
                      ? 'border-brand-400 bg-brand-50 text-brand-700'
                      : 'border-slate-200 text-slate-600 hover:border-brand-200'
                  }`}
                >
                  <Icon className="h-3.5 w-3.5" />
                  {label}
                </button>
              ))}
            </div>
          </div>

          <label className="flex items-start gap-2 text-xs text-slate-600">
            <input type="checkbox" className="mt-0.5 h-3.5 w-3.5 accent-brand-600" />
            I agree to the{' '}
            <Link href="/legal/terms" className="text-brand-700 underline">
              Terms of Service
            </Link>{' '}
            and{' '}
            <Link href="/legal/privacy" className="text-brand-700 underline">
              Privacy Policy
            </Link>
          </label>

          <button
            type="submit"
            className="w-full rounded-full bg-brand-600 py-3 text-sm font-semibold text-white transition hover:bg-brand-700"
          >
            Create Account →
          </button>

          <div className="flex items-center gap-3 text-xs text-slate-400">
            <span className="h-px flex-1 bg-slate-200" />
            OR
            <span className="h-px flex-1 bg-slate-200" />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <button
              type="button"
              className="rounded-full border border-slate-200 py-2.5 text-sm font-semibold text-slate-700"
            >
              Continue with Google
            </button>
            <button
              type="button"
              className="rounded-full border border-slate-200 py-2.5 text-sm font-semibold text-slate-700"
            >
              Continue with Apple
            </button>
          </div>

          <p className="text-center text-sm text-slate-500">
            Already have an account?{' '}
            <Link href="/login" className="font-semibold text-brand-700">
              Log In
            </Link>
          </p>
        </form>
      </div>
    </section>
  );
}
