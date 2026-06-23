import type { ResolvedNewsPost } from './fetch-news';

export const E2E_LAUNCH_SLUG = 'chisto-mk-ios-app-store-launch-2026';

const PUBLISHED_AT = '2026-06-23T06:00:00.000Z';

const EN_TITLE =
  'Chisto.mk launches on the App Store, bringing pollution reporting to iPhone users in North Macedonia';

const EN_EXCERPT =
  "The civic environmental platform went live on Apple's App Store on 23 June, offering free map-based reporting and cleanup events for residents across the country.";

const EN_BODY = [
  'SKOPJE, 23 June 2026. Chisto.mk, the civic environmental platform developed by the Ekohab association, is now available to iPhone users in North Macedonia through the App Store.',
];

const MK_TITLE = 'Chisto.mk на App Store: граѓанско пријавување загадување достапно на iPhone';

const SQ_TITLE =
  'Chisto.mk në App Store: raportimi i ndotjes për përdoruesit e iPhone në Maqedoninë e Veriut';

function postForLocale(locale: string): ResolvedNewsPost {
  const title =
    locale === 'mk' ? MK_TITLE : locale === 'sq' ? SQ_TITLE : EN_TITLE;
  const excerpt = locale === 'en' ? EN_EXCERPT : EN_EXCERPT;
  const text = locale === 'en' ? EN_BODY[0]! : EN_BODY[0]!;
  return {
    slug: E2E_LAUNCH_SLUG,
    publishedAt: PUBLISHED_AT,
    category: 'release',
    title,
    excerpt,
    body: [{ type: 'paragraph', text }],
  };
}

export function isE2eNewsFixtureEnabled(): boolean {
  return process.env.LANDING_E2E_NEWS_FIXTURE === '1';
}

export function e2eNewsPosts(locale: string): ResolvedNewsPost[] {
  return [postForLocale(locale)];
}

export function e2eNewsPostBySlug(locale: string, slug: string): ResolvedNewsPost | null {
  if (slug !== E2E_LAUNCH_SLUG) return null;
  return postForLocale(locale);
}

export function e2eNewsSlugs(): string[] {
  return [E2E_LAUNCH_SLUG];
}
