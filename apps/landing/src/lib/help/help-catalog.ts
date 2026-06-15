/**
 * Typed catalogue for Help Centre routes and hub grouping.
 * Article copy lives in next-intl messages under `helpCentre.articles.<slug>`.
 */
export const HELP_ARTICLE_SLUGS = [
  "getting-started",
  "exploring-the-map",
  "report-a-site",
  "trust-safety-and-moderation",
  "join-a-cleanup-event",
  "hosting-a-cleanup-event",
  "offline-and-slow-networks",
  "account-and-data",
  "notifications-in-the-app",
  "troubleshooting",
  "partnerships-for-organisations",
  "verifying-sites-in-the-field",
] as const;

export type HelpArticleSlug = (typeof HELP_ARTICLE_SLUGS)[number];

export type HelpCategoryId = "basics" | "map" | "reporting" | "events";

/** Column order on the hub (category headers + tiles). */
export const HELP_CATEGORY_ORDER: readonly HelpCategoryId[] = ["basics", "map", "reporting", "events"] as const;

export type HelpArticleMeta = {
  slug: HelpArticleSlug;
  categoryId: HelpCategoryId;
  /** Editorial tags for related-topic scoring (see `helpRelatedSlugs`). */
  tags?: readonly string[];
  /**
   * Optional absolute path served from `public/` (must start with `/`) for a static OG image.
   * When set, `opengraph-image` uses this asset instead of the generated title card.
   */
  publicOgImagePath?: `/${string}`;
};

export const HELP_ARTICLES: readonly HelpArticleMeta[] = [
  {
    slug: "getting-started",
    categoryId: "basics",
    tags: ["basics", "app", "onboarding", "map-entry", "first-report"],
  },
  {
    slug: "account-and-data",
    categoryId: "basics",
    tags: ["basics", "account", "privacy", "data", "safety", "trust"],
  },
  {
    slug: "notifications-in-the-app",
    categoryId: "basics",
    tags: ["basics", "notifications", "events", "reminders", "hosting"],
  },
  {
    slug: "trust-safety-and-moderation",
    categoryId: "basics",
    tags: ["basics", "safety", "moderation", "reporting", "community", "trust", "organisations"],
  },
  {
    slug: "offline-and-slow-networks",
    categoryId: "basics",
    tags: ["basics", "offline", "network", "mobile", "fixes", "troubleshooting"],
  },
  {
    slug: "troubleshooting",
    categoryId: "basics",
    tags: ["basics", "fixes", "errors", "offline", "support", "onboarding"],
  },
  {
    slug: "partnerships-for-organisations",
    categoryId: "basics",
    tags: ["basics", "organisations", "schools", "safety", "account", "trust"],
  },
  {
    slug: "exploring-the-map",
    categoryId: "map",
    tags: ["map", "navigation", "pins", "map-entry", "fieldwork", "reporting"],
  },
  {
    slug: "verifying-sites-in-the-field",
    categoryId: "map",
    tags: ["map", "fieldwork", "verification", "reporting", "pins", "navigation"],
  },
  { slug: "report-a-site", categoryId: "reporting", tags: ["reporting", "map", "photos", "safety", "map-entry", "fieldwork"] },
  { slug: "join-a-cleanup-event", categoryId: "events", tags: ["events", "volunteer", "calendar", "onboarding", "notifications"] },
  {
    slug: "hosting-a-cleanup-event",
    categoryId: "events",
    tags: ["events", "organiser", "host", "notifications", "volunteer", "calendar"],
  },
] as const;

/**
 * Manual related links override per slug. When absent, `helpRelatedSlugs` uses tag overlap (see `deriveHelpRelatedFromTags`).
 */
export const HELP_RELATED_OVERRIDES: Partial<Record<HelpArticleSlug, readonly HelpArticleSlug[]>> = {
  "getting-started": ["exploring-the-map", "report-a-site"],
  "exploring-the-map": ["report-a-site", "verifying-sites-in-the-field"],
  "report-a-site": ["exploring-the-map", "trust-safety-and-moderation"],
  "trust-safety-and-moderation": ["report-a-site", "partnerships-for-organisations"],
  "join-a-cleanup-event": ["hosting-a-cleanup-event", "getting-started"],
  "hosting-a-cleanup-event": ["join-a-cleanup-event", "notifications-in-the-app"],
  "offline-and-slow-networks": ["troubleshooting", "getting-started"],
  "account-and-data": ["trust-safety-and-moderation", "getting-started"],
  "notifications-in-the-app": ["join-a-cleanup-event", "hosting-a-cleanup-event"],
  "troubleshooting": ["offline-and-slow-networks", "getting-started"],
  "partnerships-for-organisations": ["trust-safety-and-moderation", "account-and-data"],
  "verifying-sites-in-the-field": ["exploring-the-map", "report-a-site"],
};

/** Tag overlap + same-category tie-break; used when `HELP_RELATED_OVERRIDES` has no entry for a slug. */
export function deriveHelpRelatedFromTags(slug: HelpArticleSlug): HelpArticleSlug[] {
  const self = HELP_ARTICLES.find((a) => a.slug === slug);
  if (!self) return [];
  const selfTags = new Set(self.tags ?? []);
  const scored: { rel: HelpArticleSlug; score: number }[] = [];
  for (const other of HELP_ARTICLES) {
    if (other.slug === slug) continue;
    const otherTags = new Set(other.tags ?? []);
    let overlap = 0;
    for (const t of selfTags) {
      if (otherTags.has(t)) overlap += 1;
    }
    let score = overlap * 50;
    if (other.categoryId === self.categoryId) score += 8;
    scored.push({ rel: other.slug, score });
  }
  scored.sort((a, b) => b.score - a.score || a.rel.localeCompare(b.rel));
  return scored.slice(0, 2).map((x) => x.rel);
}

/** Resolved related articles: editorial override wins; otherwise tag overlap within category. */
export function helpRelatedSlugs(slug: HelpArticleSlug): readonly HelpArticleSlug[] {
  const manual = HELP_RELATED_OVERRIDES[slug];
  if (manual != null && manual.length > 0) return manual;
  return deriveHelpRelatedFromTags(slug);
}

/** Articles whose bullet blocks feed optional HowTo JSON-LD (step-heavy guides). */
export const HELP_ARTICLES_HOWTO_JSONLD: readonly HelpArticleSlug[] = [
  "report-a-site",
  "join-a-cleanup-event",
  "hosting-a-cleanup-event",
] as const;

export function isHelpArticleSlug(value: string): value is HelpArticleSlug {
  return (HELP_ARTICLE_SLUGS as readonly string[]).includes(value);
}

export function helpArticleMeta(slug: string): HelpArticleMeta | undefined {
  return HELP_ARTICLES.find((a) => a.slug === slug);
}

export function articlesInCategory(categoryId: HelpCategoryId): HelpArticleMeta[] {
  return HELP_ARTICLES.filter((a) => a.categoryId === categoryId);
}
