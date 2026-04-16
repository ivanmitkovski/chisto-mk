/** @vitest-environment jsdom */
import React from "react";
import { describe, expect, it, vi, beforeEach } from "vitest";
import { fireEvent, render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { HelpTopicFilterItem } from "@/lib/help/filter-help-topics";
import { HelpSearch } from "./HelpSearch";

const replace = vi.hoisted(() => vi.fn());
let searchParams = new URLSearchParams();

vi.mock("next/navigation", () => ({
  useSearchParams: () => searchParams,
}));

vi.mock("@/i18n/routing", () => ({
  Link: ({ href, children }: { href: string; children: React.ReactNode }) =>
    React.createElement("a", { href }, children),
  useRouter: () => ({ replace: replace }),
  usePathname: () => "/en/help",
}));

vi.mock("@/lib/analytics/track-help", () => ({
  trackHelpEvent: vi.fn(),
}));

vi.mock("framer-motion", async (importOriginal) => {
  const actual = await importOriginal<typeof import("framer-motion")>();
  return {
    ...actual,
    useReducedMotion: () => true,
  };
});

function hubT(key: string, values?: { count?: number }) {
  const hub: Record<string, string> = {
    searchLabel: "Search help",
    searchPlaceholder: "Search…",
    clearSearch: "Clear",
    suggestedIntro: "Popular",
    empty: "No topics match",
    searchTipsTitle: "Tips",
    searchResultsLabel: "Search results",
    searchAnnounceEmpty: "No matches",
    jumpToCategoryNav: "Browse categories",
    jumpToCategoryLead: "Jump to section",
  };
  if (key === "searchAnnounceResults" && values?.count != null) {
    return `${values.count} topics match`;
  }
  return hub[key] ?? key;
}

vi.mock("next-intl", () => ({
  useTranslations: (namespace: string) => {
    if (namespace === "helpCentre.hub") {
      const fn = Object.assign(
        (key: string, values?: { count?: number }) => hubT(key, values),
        {
          raw: (key: string) => {
            if (key === "searchTips") return ["Tip line"];
            return [];
          },
        },
      );
      return fn;
    }
    if (namespace === "helpCentre.categories") {
      return (key: string) =>
        (
          {
            "basics.label": "Basics",
            "map.label": "Map",
            "reporting.label": "Reporting",
            "events.label": "Events",
          } as Record<string, string>
        )[key] ?? key;
    }
    return (key: string) => {
      const titles: Record<string, string> = {
        "articles.getting-started.cardTitle": "Getting started",
        "articles.exploring-the-map.cardTitle": "Map",
        "articles.report-a-site.cardTitle": "Report",
        "articles.offline-and-slow-networks.cardTitle": "Offline",
        "articles.troubleshooting.cardTitle": "Troubleshoot",
      };
      return titles[key] ?? key;
    };
  },
}));

const topics: HelpTopicFilterItem[] = [
  {
    slug: "getting-started",
    categoryId: "basics",
    categoryLabel: "Basics",
    cardTitle: "Getting started",
    cardSummary: "Install and account",
    readTime: "4 min",
  },
  {
    slug: "exploring-the-map",
    categoryId: "map",
    categoryLabel: "Map",
    cardTitle: "Exploring the map",
    cardSummary: "Pan and zoom",
    readTime: "5 min",
  },
];

describe("HelpSearch", () => {
  beforeEach(() => {
    replace.mockClear();
    searchParams = new URLSearchParams();
  });

  it("keeps a stable help-search-results region in the document", () => {
    render(React.createElement(HelpSearch, { topics }));
    const region = screen.getByRole("region", { name: "Search results" });
    expect(region).toHaveAttribute("id", "help-search-results");
  });

  it("shows category jump links when search is empty", () => {
    render(React.createElement(HelpSearch, { topics }));
    expect(screen.getByRole("navigation", { name: "Browse categories" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Basics" })).toHaveAttribute("href", "#help-cat-basics");
  });

  it("exposes listbox options when topics match", async () => {
    const user = userEvent.setup();
    render(React.createElement(HelpSearch, { topics }));
    await user.type(screen.getByPlaceholderText("Search…"), "map");
    const region = screen.getByRole("region", { name: "Search results" });
    const listbox = within(region).getByRole("listbox");
    expect(within(listbox).getAllByRole("option").length).toBeGreaterThan(0);
  });

  it("debounces syncing the trimmed query into the URL", async () => {
    vi.useFakeTimers();
    render(React.createElement(HelpSearch, { topics }));
    const input = screen.getByPlaceholderText("Search…");
    fireEvent.change(input, { target: { value: "abc" } });
    expect(replace).not.toHaveBeenCalled();
    await vi.advanceTimersByTimeAsync(350);
    expect(replace).toHaveBeenCalledWith("/en/help?q=abc", { scroll: false });
    vi.useRealTimers();
  });
});
