import { describe, expect, it } from "vitest";
import type { HelpArticleSlug } from "./help-catalog";
import {
  filterAndRankHelpTopics,
  filterHelpTopics,
  foldForSearch,
  normalizeHelpSearchQuery,
  rankHelpTopicsByQueryRelevance,
  type HelpTopicFilterItem,
} from "./filter-help-topics";

const sample: HelpTopicFilterItem[] = [
  {
    slug: "getting-started",
    categoryId: "basics",
    categoryLabel: "Getting started",
    cardTitle: "Get started with Chisto.mk",
    cardSummary: "Download the app and pick your language.",
    readTime: "4 min",
  },
  {
    slug: "report-a-site",
    categoryId: "reporting",
    categoryLabel: "Reporting",
    cardTitle: "Report a polluted site",
    cardSummary: "Photos, map pin, and what happens after you submit.",
    readTime: "5 min",
  },
];

describe("filterHelpTopics", () => {
  it("returns all items for blank query", () => {
    expect(filterHelpTopics(sample, "")).toHaveLength(2);
    expect(filterHelpTopics(sample, "   ")).toHaveLength(2);
  });

  it("matches every word in the query", () => {
    expect(filterHelpTopics(sample, "report photo")).toHaveLength(1);
    expect(filterHelpTopics(sample, "report photo")[0]?.slug).toBe("report-a-site");
  });

  it("matches category labels", () => {
    expect(filterHelpTopics(sample, "reporting")).toHaveLength(1);
  });

  it("returns empty when nothing matches", () => {
    expect(filterHelpTopics(sample, "zzz")).toHaveLength(0);
  });

  it("matches slug words when the title omits the term", () => {
    const items: HelpTopicFilterItem[] = [
      {
        slug: "offline-and-slow-networks",
        categoryId: "basics",
        categoryLabel: "Basics",
        cardTitle: "Slow connections",
        cardSummary: "Tips when data drops.",
        readTime: "4 min",
      },
    ];
    expect(filterHelpTopics(items, "offline")).toHaveLength(1);
  });
});

describe("normalizeHelpSearchQuery", () => {
  it("trims and lowercases", () => {
    expect(normalizeHelpSearchQuery("  Hello ")).toBe("hello");
  });
});

describe("foldForSearch", () => {
  it("strips combining marks for matching", () => {
    expect(foldForSearch("Café résumé")).toBe("cafe resume");
  });
});

describe("filterHelpTopics with folded haystack", () => {
  it("matches when query is ASCII but copy uses accents", () => {
    const items: HelpTopicFilterItem[] = [
      {
        slug: "getting-started",
        categoryId: "basics",
        categoryLabel: "Basics",
        cardTitle: "Café onboarding",
        cardSummary: "Start here",
        readTime: "1 min",
      },
    ];
    expect(filterHelpTopics(items, "cafe")).toHaveLength(1);
  });
});

const rankingFixture: HelpTopicFilterItem[] = [
  {
    slug: "report-a-site",
    categoryId: "reporting",
    categoryLabel: "Reporting",
    cardTitle: "Report a polluted site",
    cardSummary: "Photos, map pin, and what happens after you submit.",
    readTime: "5 min",
  },
  {
    slug: "trust-safety-and-moderation",
    categoryId: "basics",
    categoryLabel: "Get started",
    cardTitle: "Trust, safety, moderation",
    cardSummary: "Community reporting and what moderators review.",
    readTime: "6 min",
  },
  {
    slug: "getting-started",
    categoryId: "basics",
    categoryLabel: "Get started",
    cardTitle: "Getting started",
    cardSummary: "Install first, then explore reporting later.",
    readTime: "4 min",
  },
  {
    slug: "exploring-the-map",
    categoryId: "map",
    categoryLabel: "Map",
    cardTitle: "Map basics",
    cardSummary: "Pan, zoom, and labels without reporting.",
    readTime: "5 min",
  },
];

const titleBoostFixture: HelpTopicFilterItem[] = [
  {
    slug: "getting-started",
    categoryId: "basics",
    categoryLabel: "Basics",
    cardTitle: "Alpha beta overview",
    cardSummary: "Short summary.",
    readTime: "1 min",
  },
  {
    slug: "report-a-site",
    categoryId: "reporting",
    categoryLabel: "Reporting",
    cardTitle: "Different title",
    cardSummary: "Alpha and beta appear only in the summary text.",
    readTime: "1 min",
  },
];

describe("rankHelpTopicsByQueryRelevance", () => {
  it("prefers stronger title matches when every word matches", () => {
    const filtered = filterHelpTopics(titleBoostFixture, "alpha beta");
    const ranked = rankHelpTopicsByQueryRelevance(filtered, "alpha beta");
    expect(ranked[0]?.slug).toBe("getting-started");
  });

  it("applies pinned order as a tie boost", () => {
    const filtered = filterHelpTopics(rankingFixture, "map");
    const ranked = rankHelpTopicsByQueryRelevance(filtered, "map", {
      pinnedSlugs: ["exploring-the-map", "report-a-site"],
    });
    expect(ranked[0]?.slug).toBe("exploring-the-map");
  });
});

describe("filterAndRankHelpTopics", () => {
  it("matches filterHelpTopics when query is blank", () => {
    expect(filterAndRankHelpTopics(sample, "")).toEqual(filterHelpTopics(sample, ""));
  });

  it("golden: multi-word query order is stable", () => {
    const golden: { query: string; expectedOrder: HelpArticleSlug[] }[] = [
      {
        query: "alpha beta",
        expectedOrder: ["getting-started", "report-a-site"],
      },
      {
        query: "report map",
        expectedOrder: ["exploring-the-map", "report-a-site"],
      },
    ];
    for (const { query, expectedOrder } of golden) {
      const fixture = query === "alpha beta" ? titleBoostFixture : rankingFixture;
      expect(filterAndRankHelpTopics(fixture, query).map((x) => x.slug)).toEqual(expectedOrder);
    }
  });
});
