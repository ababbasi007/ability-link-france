import type { Metadata } from 'next';
import Image from 'next/image';
import {
  Search,
  Navigation,
  MapPin,
  Star,
  Hospital,
  GraduationCap,
  Camera,
  Bus,
  UtensilsCrossed,
  Building2,
  Trees,
  ShoppingBag,
} from 'lucide-react';
import { BottomCta } from '@/components/marketing/BottomCta';

export const metadata: Metadata = { title: 'Ability Map' };

const categories = [
  { icon: Hospital, label: 'Hospitals' },
  { icon: GraduationCap, label: 'Education' },
  { icon: Camera, label: 'Tourism' },
  { icon: Bus, label: 'Transport' },
  { icon: UtensilsCrossed, label: 'Restaurants' },
  { icon: Building2, label: 'Government' },
  { icon: Trees, label: 'Parks' },
  { icon: ShoppingBag, label: 'Shopping' },
];

const accessibilityFeatures = [
  'Wheelchair Accessible',
  'Accessible Washrooms',
  'Ramps',
  'Elevators',
  'Braille / Tactile Signs',
  'Hearing Assistance',
  'Accessible Parking',
  'Sensory Friendly',
];

const nearbyPlaces = [
  { name: 'Shifa International Hospital', type: 'Hospital', rating: '4.5 (320)', distance: '2.3 km away' },
  { name: 'Centaurus Mall', type: 'Shopping Mall', rating: '4.3 (210)', distance: '3.1 km away' },
  { name: 'F-9 Park', type: 'Park', rating: '4.6 (140)', distance: '1.8 km away' },
  { name: 'Islamabad Serena Hotel', type: 'Hotel', rating: '4.7 (98)', distance: '4.0 km away' },
];

export default function AbilityMapPage() {
  return (
    <>
      <section className="bg-gradient-to-b from-brand-50/70 to-white py-10">
        <div className="mx-auto max-w-page px-4 sm:px-6">
          <p className="text-xs font-bold uppercase tracking-[0.14em] text-brand-600">
            Ability Map
          </p>
          <h1 className="balance mt-3 max-w-2xl text-4xl font-extrabold leading-[1.08] text-slate-900 sm:text-5xl">
            Explore a More
            <br />
            <span className="text-brand-600">Accessible World</span>
          </h1>
          <p className="mt-4 max-w-xl text-base text-slate-500">
            Find accessible places, services and opportunities near you or in
            any city. Together, we make travel, work and daily life more
            inclusive.
          </p>

          <div className="mt-6 flex flex-col gap-2 sm:flex-row">
            <div className="flex flex-1 items-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-3 shadow-sm">
              <Search className="h-4 w-4 text-slate-400" />
              <input
                type="text"
                placeholder="Search for a city, place or service (e.g. hospital, hotel, park...)"
                className="w-full min-w-0 text-sm outline-none placeholder:text-slate-400"
              />
            </div>
            <button className="rounded-full bg-brand-600 px-6 py-3 text-sm font-semibold text-white transition hover:bg-brand-700">
              Search
            </button>
            <button className="flex items-center justify-center gap-2 rounded-full border border-slate-200 bg-white px-5 py-3 text-sm font-semibold text-slate-700">
              <Navigation className="h-4 w-4" />
              Use My Location
            </button>
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-page px-4 pb-14 sm:px-6">
        <div className="grid gap-6 lg:grid-cols-[280px_1fr]">
          <aside className="space-y-6 rounded-2xl border border-slate-100 p-5">
            <div>
              <h3 className="mb-3 text-sm font-bold text-slate-900">Category</h3>
              <div className="grid grid-cols-2 gap-2">
                {categories.map(({ icon: Icon, label }) => (
                  <label
                    key={label}
                    className="flex cursor-pointer items-center gap-2 rounded-lg border border-slate-100 px-2.5 py-2 text-xs font-medium text-slate-600 hover:border-brand-200"
                  >
                    <input type="checkbox" className="h-3.5 w-3.5 accent-brand-600" />
                    <Icon className="h-3.5 w-3.5 text-brand-600" />
                    {label}
                  </label>
                ))}
              </div>
            </div>

            <div>
              <h3 className="mb-3 text-sm font-bold text-slate-900">
                Accessibility Features
              </h3>
              <div className="space-y-2">
                {accessibilityFeatures.map((f) => (
                  <label
                    key={f}
                    className="flex cursor-pointer items-center gap-2 text-xs font-medium text-slate-600"
                  >
                    <input type="checkbox" className="h-3.5 w-3.5 accent-brand-600" />
                    {f}
                  </label>
                ))}
              </div>
            </div>

            <button className="w-full rounded-full bg-brand-600 py-2.5 text-sm font-semibold text-white">
              Apply Filters
            </button>
          </aside>

          <div className="space-y-4">
            <div className="relative aspect-[16/10] w-full overflow-hidden rounded-2xl border border-slate-100">
              <Image
                src="https://picsum.photos/seed/ability-map/1000/620"
                alt="Interactive map placeholder — to be replaced with a live Leaflet/Google Maps view of nearby accessible places"
                fill
                sizes="(min-width: 1024px) 700px, 100vw"
                className="object-cover"
              />
              <div className="absolute left-4 top-4 rounded-xl bg-white/95 px-3 py-1.5 text-xs font-semibold text-slate-600 shadow">
                Map view — live pins load here
              </div>
              <div className="absolute bottom-4 right-4 w-56 rounded-xl bg-white p-3 shadow-lg">
                <p className="flex items-center gap-1.5 text-sm font-semibold text-slate-900">
                  <MapPin className="h-4 w-4 text-brand-600" />
                  Ayub Medical Complex
                </p>
                <p className="mt-1 flex items-center gap-1 text-xs text-slate-500">
                  <Star className="h-3 w-3 fill-amber-400 text-amber-400" />
                  4.2 (320 reviews) · Hospital · 2.1 km
                </p>
                <button className="mt-2 w-full rounded-full bg-brand-600 py-1.5 text-xs font-semibold text-white">
                  Get Directions
                </button>
              </div>
            </div>

            <div>
              <h3 className="mb-3 text-sm font-bold text-slate-900">
                Nearby Places
              </h3>
              <div className="grid gap-3 sm:grid-cols-2">
                {nearbyPlaces.map((p) => (
                  <div
                    key={p.name}
                    className="flex items-center gap-3 rounded-xl border border-slate-100 p-3"
                  >
                    <span className="grid h-11 w-11 shrink-0 place-items-center rounded-lg bg-brand-50 text-brand-600">
                      <MapPin className="h-4 w-4" />
                    </span>
                    <div className="min-w-0">
                      <p className="truncate text-sm font-semibold text-slate-900">
                        {p.name}
                      </p>
                      <p className="text-xs text-slate-500">
                        {p.type} · {p.distance}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      <BottomCta
        heading="Map a More Inclusive Tomorrow"
        subheading="Add accessible places, suggest updates, and help our community grow."
        label="Suggest a Place"
      />
    </>
  );
}
