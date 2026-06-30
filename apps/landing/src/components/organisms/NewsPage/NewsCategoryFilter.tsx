"use client";

import { useSearchParams } from "next/navigation";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/routing";
import type { NewsCategory } from "@/data/news-posts";
import { parseNewsHubCategory } from "@/lib/news/news-hub-params";
import { trackNewsEvent } from "@/lib/analytics/track-news";
import { cn } from "@/lib/utils/cn";

const CATEGORIES: NewsCategory[] = ["release", "partnership", "community", "product"];

type NewsCategoryFilterProps = {
  allLabel: string;
};

function chipClass(active: boolean) {
  return cn(
    "inline-flex rounded-full px-3 py-1 text-xs font-semibold uppercase tracking-wide transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2",
    active
      ? "bg-gray-900 text-white shadow-sm"
      : "bg-white/80 text-primary-800 ring-1 ring-primary/20 hover:bg-primary/10",
  );
}

export function NewsCategoryFilter({ allLabel }: NewsCategoryFilterProps) {
  const searchParams = useSearchParams();
  const t = useTranslations("newsPage");
  const activeCategory = parseNewsHubCategory(searchParams.get("category"));

  function categoryLabel(category: NewsCategory) {
    return t(`newsCategory.${category}`);
  }

  function hrefFor(category: NewsCategory | null) {
    const params = new URLSearchParams(searchParams.toString());
    params.delete("page");
    if (category) {
      params.set("category", category);
    } else {
      params.delete("category");
    }
    const qs = params.toString();
    return qs ? `/news?${qs}` : "/news";
  }

  function onFilterClick(category: NewsCategory | "all") {
    trackNewsEvent("news_hub_filter", { category });
  }

  return (
    <div className="mt-8 flex flex-wrap gap-2" role="group" aria-label={allLabel}>
      <Link
        href={hrefFor(null)}
        className={chipClass(!activeCategory)}
        onClick={() => onFilterClick("all")}
      >
        {allLabel}
      </Link>
      {CATEGORIES.map((category) => (
        <Link
          key={category}
          href={hrefFor(category)}
          className={chipClass(activeCategory === category)}
          onClick={() => onFilterClick(category)}
        >
          {categoryLabel(category)}
        </Link>
      ))}
    </div>
  );
}
