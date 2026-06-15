"use client";

import {
  useDeferredValue,
  useEffect,
  useMemo,
  useRef,
  useState,
  type KeyboardEvent,
} from "react";
import { useSearchParams } from "next/navigation";
import { useTranslations } from "next-intl";
import { Search, X } from "lucide-react";
import { Link, usePathname, useRouter } from "@/i18n/routing";
import { trackHelpEvent } from "@/lib/analytics/track-help";
import { HELP_CATEGORY_ORDER } from "@/lib/help/help-catalog";
import type { HelpArticleSlug } from "@/lib/help/help-catalog";
import { filterAndRankHelpTopics, type HelpTopicFilterItem } from "@/lib/help/filter-help-topics";
import { cn } from "@/lib/utils/cn";
import { HelpTopicCard } from "./HelpTopicCard";

const SUGGESTED_SLUGS: readonly HelpArticleSlug[] = [
  "getting-started",
  "exploring-the-map",
  "report-a-site",
  "offline-and-slow-networks",
  "troubleshooting",
];

const URL_SYNC_MS = 320;

export function HelpSearch({
  topics,
  pinnedSlugs = [],
}: {
  topics: readonly HelpTopicFilterItem[];
  /** Small relevance boost for hub-featured articles when scores tie. */
  pinnedSlugs?: readonly HelpArticleSlug[];
}) {
  const t = useTranslations("helpCentre.hub");
  const tCats = useTranslations("helpCentre.categories");
  const tArticles = useTranslations("helpCentre");
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [query, setQuery] = useState(() => searchParams.get("q") ?? "");
  const deferredQuery = useDeferredValue(query);
  const [selectedIndex, setSelectedIndex] = useState(-1);
  const inputRef = useRef<HTMLInputElement>(null);

  const filtered = useMemo(
    () => filterAndRankHelpTopics(topics, deferredQuery, { pinnedSlugs }),
    [topics, deferredQuery, pinnedSlugs],
  );

  const flatOrder = useMemo(() => {
    const out: HelpTopicFilterItem[] = [];
    for (const categoryId of HELP_CATEGORY_ORDER) {
      for (const item of filtered) {
        if (item.categoryId === categoryId) out.push(item);
      }
    }
    return out;
  }, [filtered]);

  const announce = useMemo(() => {
    const q = deferredQuery.trim();
    if (q.length === 0) return "";
    if (filtered.length === 0) return t("searchAnnounceEmpty");
    return t("searchAnnounceResults", { count: filtered.length });
  }, [deferredQuery, filtered.length, t]);

  const searchParamsKey = searchParams.toString();
  useEffect(() => {
    const fromUrl = searchParams.get("q") ?? "";
    setQuery((prev) => (prev === fromUrl ? prev : fromUrl));
  }, [searchParamsKey, searchParams]);

  useEffect(() => {
    setSelectedIndex(-1);
  }, [deferredQuery]);

  useEffect(() => {
    const q = query.trim();
    if (q.length < 2) return;
    const timer = window.setTimeout(() => {
      trackHelpEvent("help_search", { q: q.slice(0, 64) });
    }, 400);
    return () => window.clearTimeout(timer);
  }, [query]);

  useEffect(() => {
    const timer = window.setTimeout(() => {
      const params = new URLSearchParams(searchParams.toString());
      const trimmed = query.trim();
      if (trimmed) params.set("q", trimmed);
      else params.delete("q");
      const qs = params.toString();
      const nextPath = qs ? `${pathname}?${qs}` : pathname;
      const curPath = `${pathname}${searchParams.toString() ? `?${searchParams.toString()}` : ""}`;
      if (nextPath === curPath) return;
      router.replace(nextPath, { scroll: false });
    }, URL_SYNC_MS);
    return () => window.clearTimeout(timer);
  }, [query, pathname, router, searchParams]);

  function onSearchKeyDown(e: KeyboardEvent<HTMLInputElement>) {
    if (e.key === "ArrowDown" && flatOrder.length > 0) {
      e.preventDefault();
      setSelectedIndex((i) => (i < 0 ? 0 : Math.min(i + 1, flatOrder.length - 1)));
    } else if (e.key === "ArrowUp" && flatOrder.length > 0) {
      e.preventDefault();
      setSelectedIndex((i) => (i <= 0 ? -1 : i - 1));
    } else if (e.key === "Enter" && selectedIndex >= 0 && flatOrder[selectedIndex]) {
      e.preventDefault();
      router.push(`/help/${flatOrder[selectedIndex]!.slug}`);
    } else if (e.key === "Escape") {
      setQuery("");
      inputRef.current?.blur();
    }
  }

  return (
    <div className="mt-0 space-y-8 md:space-y-10" role="search">
      <p className="sr-only" aria-live="polite" aria-atomic="true">
        {announce}
      </p>

      {deferredQuery.trim().length === 0 ? (
        <nav aria-label={t("jumpToCategoryNav")} className="max-w-xl">
          <p className="text-xs font-semibold uppercase tracking-[0.12em] text-gray-500">{t("jumpToCategoryLead")}</p>
          <ul className="mt-2 flex flex-wrap gap-2">
            {HELP_CATEGORY_ORDER.map((categoryId) => (
              <li key={categoryId}>
                <a
                  href={`#help-cat-${categoryId}`}
                  className="inline-flex rounded-full border border-gray-200/90 bg-white px-3 py-1.5 text-sm font-medium text-gray-800 shadow-sm transition-colors hover:border-primary/30 hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
                >
                  {tCats(`${categoryId}.label`)}
                </a>
              </li>
            ))}
          </ul>
        </nav>
      ) : null}

      <div className="relative max-w-xl">
        <label htmlFor="help-search" className="sr-only">
          {t("searchLabel")}
        </label>
        <Search
          className="pointer-events-none absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-400"
          strokeWidth={1.75}
          aria-hidden
        />
        <input
          ref={inputRef}
          id="help-search"
          type="search"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={onSearchKeyDown}
          placeholder={t("searchPlaceholder")}
          autoComplete="off"
          aria-controls="help-search-results"
          aria-activedescendant={
            selectedIndex >= 0 && flatOrder[selectedIndex] ? `help-result-${flatOrder[selectedIndex]!.slug}` : undefined
          }
          className="w-full rounded-2xl border border-gray-200/90 bg-white py-3.5 pl-12 pr-12 text-[0.9375rem] text-gray-900 shadow-inner shadow-black/[0.02] outline-none ring-primary/25 transition-shadow placeholder:text-gray-400 focus:border-primary/30 focus:ring-2"
        />
        {query.trim().length > 0 ? (
          <button
            type="button"
            className="absolute right-3 top-1/2 flex h-9 w-9 -translate-y-1/2 items-center justify-center rounded-lg text-gray-500 transition-colors hover:bg-gray-100 hover:text-gray-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
            onClick={() => {
              setQuery("");
              inputRef.current?.focus();
            }}
            aria-label={t("clearSearch")}
          >
            <X className="h-5 w-5" strokeWidth={1.75} />
          </button>
        ) : null}
      </div>

      <div className="max-w-xl">
        <p className="text-xs font-semibold uppercase tracking-[0.12em] text-gray-500">{t("searchTipsTitle")}</p>
        <ul className="mt-3 list-disc space-y-1.5 pl-5 text-sm leading-relaxed text-gray-600">
          {(t.raw("searchTips") as string[]).map((line) => (
            <li key={line} className="text-pretty">
              {line}
            </li>
          ))}
        </ul>
      </div>

      <div
        id="help-search-results"
        role="region"
        aria-label={t("searchResultsLabel")}
        className={cn(
          deferredQuery.trim().length > 0 && filtered.length === 0 ? "space-y-4" : "space-y-10 md:space-y-12",
        )}
      >
        {filtered.length === 0 ? (
          <div className="space-y-4">
            <p className="text-sm text-gray-600 md:text-base">{t("empty")}</p>
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.12em] text-gray-500">{t("suggestedIntro")}</p>
              <ul className="mt-3 flex flex-col gap-2 sm:flex-row sm:flex-wrap">
                {SUGGESTED_SLUGS.map((slug) => (
                  <li key={slug}>
                    <Link
                      href={`/help/${slug}`}
                      className="inline-flex rounded-full border border-gray-200/90 bg-white px-4 py-2 text-sm font-medium text-gray-800 shadow-sm transition-colors hover:border-primary/30 hover:text-primary"
                    >
                      {tArticles(`articles.${slug}.cardTitle`)}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        ) : (
          (() => {
            let firstCategory = true;
            return HELP_CATEGORY_ORDER.map((categoryId) => {
              const inCat = filtered.filter((x) => x.categoryId === categoryId);
              if (inCat.length === 0) return null;
              const showTopRule = !firstCategory;
              firstCategory = false;
              return (
                <section
                  key={categoryId}
                  aria-labelledby={`help-cat-${categoryId}`}
                  className={cn(showTopRule && "border-t border-gray-200/80 pt-10 md:pt-12")}
                >
                  <h2
                    id={`help-cat-${categoryId}`}
                    className="text-xs font-semibold uppercase tracking-[0.14em] text-gray-600 md:text-[0.8125rem]"
                  >
                    {tCats(`${categoryId}.label`)}
                  </h2>
                  <ul
                    className="mt-5 grid gap-4 sm:grid-cols-2 md:mt-6 md:gap-5 xl:grid-cols-3"
                    role="listbox"
                    aria-labelledby={`help-cat-${categoryId}`}
                  >
                    {inCat.map((item, i) => {
                      const globalIdx = flatOrder.findIndex((x) => x.slug === item.slug);
                      const selected = selectedIndex >= 0 && globalIdx === selectedIndex;
                      return (
                        <li
                          key={item.slug}
                          id={`help-result-${item.slug}`}
                          role="option"
                          aria-selected={selected}
                          className="min-h-[8.5rem]"
                        >
                          <HelpTopicCard
                            slug={item.slug}
                            title={item.cardTitle}
                            summary={item.cardSummary}
                            readTime={item.readTime}
                            index={i}
                            selected={selected}
                            highlightQuery={deferredQuery}
                          />
                        </li>
                      );
                    })}
                  </ul>
                </section>
              );
            });
          })()
        )}
      </div>
    </div>
  );
}
