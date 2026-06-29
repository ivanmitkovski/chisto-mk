/**
 * Typed catalogue for Help Centre routes and hub grouping.
 * Article copy lives in next-intl messages under `helpCentre.articles.<slug>`.
 */
export const HELP_ARTICLE_SLUGS = [
  "getting-started",
  "sign-in-and-verification",
  "app-permissions",
  "offline-and-slow-networks",
  "troubleshooting",
  "partnerships-for-organisations",
  "home-feed-and-sites",
  "exploring-the-map",
  "verifying-sites-in-the-field",
  "report-a-site",
  "report-statuses-and-drafts",
  "join-a-cleanup-event",
  "event-check-in-and-chat",
  "hosting-a-cleanup-event",
  "your-profile-and-settings",
  "points-rankings-and-credits",
  "account-and-data",
  "notifications-in-the-app",
  "trust-safety-and-moderation",
] as const;

export type HelpArticleSlug = (typeof HELP_ARTICLE_SLUGS)[number];

export type HelpCategoryId = "basics" | "map" | "reporting" | "events" | "profile";

/** Column order on the hub (category headers + tiles). */
export const HELP_CATEGORY_ORDER: readonly HelpCategoryId[] = [
  "basics",
  "map",
  "reporting",
  "events",
  "profile",
] as const;

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
    tags: ["basics", "app", "onboarding", "map-entry", "first-report", "permissions"],
  },
  {
    slug: "sign-in-and-verification",
    categoryId: "basics",
    tags: ["basics", "account", "onboarding", "fixes", "permissions"],
  },
  {
    slug: "app-permissions",
    categoryId: "basics",
    tags: ["basics", "permissions", "fixes", "onboarding", "mobile"],
  },
  {
    slug: "offline-and-slow-networks",
    categoryId: "basics",
    tags: ["basics", "offline", "network", "mobile", "fixes", "troubleshooting", "reporting"],
  },
  {
    slug: "troubleshooting",
    categoryId: "basics",
    tags: ["basics", "fixes", "errors", "offline", "support", "onboarding", "permissions"],
  },
  {
    slug: "partnerships-for-organisations",
    categoryId: "basics",
    tags: ["basics", "organisations", "schools", "safety", "account", "trust"],
  },
  {
    slug: "home-feed-and-sites",
    categoryId: "map",
    tags: ["map", "feed", "pins", "navigation", "reporting", "community"],
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
  {
    slug: "report-a-site",
    categoryId: "reporting",
    tags: ["reporting", "map", "photos", "safety", "map-entry", "fieldwork", "offline"],
  },
  {
    slug: "report-statuses-and-drafts",
    categoryId: "reporting",
    tags: ["reporting", "offline", "fixes", "onboarding"],
  },
  {
    slug: "join-a-cleanup-event",
    categoryId: "events",
    tags: ["events", "volunteer", "calendar", "onboarding", "notifications"],
  },
  {
    slug: "event-check-in-and-chat",
    categoryId: "events",
    tags: ["events", "volunteer", "notifications", "hosting", "permissions"],
  },
  {
    slug: "hosting-a-cleanup-event",
    categoryId: "events",
    tags: ["events", "organiser", "host", "notifications", "volunteer", "calendar"],
  },
  {
    slug: "your-profile-and-settings",
    categoryId: "profile",
    tags: ["profile", "account", "onboarding", "permissions"],
  },
  {
    slug: "points-rankings-and-credits",
    categoryId: "profile",
    tags: ["profile", "reporting", "events", "community"],
  },
  {
    slug: "account-and-data",
    categoryId: "profile",
    tags: ["profile", "account", "privacy", "data", "safety", "trust"],
  },
  {
    slug: "notifications-in-the-app",
    categoryId: "profile",
    tags: ["profile", "notifications", "events", "reminders", "hosting"],
  },
  {
    slug: "trust-safety-and-moderation",
    categoryId: "profile",
    tags: ["profile", "safety", "moderation", "reporting", "community", "trust", "organisations"],
  },
] as const;

/**
 * Manual related links override per slug. When absent, `helpRelatedSlugs` uses tag overlap (see `deriveHelpRelatedFromTags`).
 */
export const HELP_RELATED_OVERRIDES: Partial<Record<HelpArticleSlug, readonly HelpArticleSlug[]>> = {
  "getting-started": ["sign-in-and-verification", "report-a-site"],
  "sign-in-and-verification": ["app-permissions", "troubleshooting"],
  "app-permissions": ["troubleshooting", "getting-started"],
  "home-feed-and-sites": ["exploring-the-map", "report-a-site"],
  "exploring-the-map": ["home-feed-and-sites", "verifying-sites-in-the-field"],
  "report-a-site": ["report-statuses-and-drafts", "app-permissions"],
  "report-statuses-and-drafts": ["report-a-site", "offline-and-slow-networks"],
  "join-a-cleanup-event": ["event-check-in-and-chat", "getting-started"],
  "event-check-in-and-chat": ["join-a-cleanup-event", "notifications-in-the-app"],
  "hosting-a-cleanup-event": ["event-check-in-and-chat", "points-rankings-and-credits"],
  "your-profile-and-settings": ["account-and-data", "notifications-in-the-app"],
  "points-rankings-and-credits": ["report-a-site", "join-a-cleanup-event"],
  "offline-and-slow-networks": ["troubleshooting", "report-statuses-and-drafts"],
  "account-and-data": ["trust-safety-and-moderation", "your-profile-and-settings"],
  "notifications-in-the-app": ["join-a-cleanup-event", "event-check-in-and-chat"],
  "troubleshooting": ["app-permissions", "offline-and-slow-networks"],
  "trust-safety-and-moderation": ["report-a-site", "partnerships-for-organisations"],
  "partnerships-for-organisations": ["trust-safety-and-moderation", "account-and-data"],
  "verifying-sites-in-the-field": ["home-feed-and-sites", "exploring-the-map"],
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

/** Articles whose bullet/step blocks feed optional HowTo JSON-LD (step-heavy guides). */
export const HELP_ARTICLES_HOWTO_JSONLD: readonly HelpArticleSlug[] = [
  "getting-started",
  "sign-in-and-verification",
  "report-a-site",
  "join-a-cleanup-event",
  "hosting-a-cleanup-event",
  "event-check-in-and-chat",
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
