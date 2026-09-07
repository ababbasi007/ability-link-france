import { Hero } from './Hero';
import { CategoryPillTabs } from './CategoryPillTabs';
import { CategoryGrid } from './CategoryGrid';
import { FeaturedGrid } from './FeaturedGrid';
import { HowItWorks } from './HowItWorks';
import { Testimonials } from './Testimonials';
import { BottomCta } from './BottomCta';
import type { VerticalPageContent } from '@/lib/types';

export function VerticalPage({ content }: { content: VerticalPageContent }) {
  return (
    <>
      <Hero
        eyebrow={content.eyebrow}
        title={content.title}
        titleAccent={content.titleAccent}
        subtitle={content.subtitle}
        image={content.heroImage}
        handwrittenCaption={content.handwrittenCaption}
        searchPlaceholder={content.searchPlaceholder}
        trustBadges={content.trustBadges}
        quickLinks={content.quickLinks}
      />

      <div className="mx-auto max-w-page px-4 sm:px-6">
        <CategoryPillTabs tabs={content.tabs} />
      </div>

      <CategoryGrid
        heading={content.categoriesHeading}
        subheading={content.categoriesSubheading}
        items={content.categories}
      />

      <FeaturedGrid
        heading={content.featuredHeading}
        subheading={content.featuredSubheading}
        items={content.featured}
      />

      <HowItWorks heading={content.howItWorksHeading} steps={content.howItWorks} />

      <Testimonials
        heading={content.testimonialsHeading}
        items={content.testimonials}
      />

      <BottomCta
        heading={content.ctaHeading}
        subheading={content.ctaSubheading}
        label={content.ctaLabel}
      />
    </>
  );
}
