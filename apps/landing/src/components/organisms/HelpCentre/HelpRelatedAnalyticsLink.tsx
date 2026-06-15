"use client";

import { Link } from "@/i18n/routing";
import { trackHelpEvent } from "@/lib/analytics/track-help";
import type { HelpArticleSlug } from "@/lib/help/help-catalog";

export function HelpRelatedAnalyticsLink({
  slug,
  fromSlug,
  className,
  children,
}: {
  slug: HelpArticleSlug;
  fromSlug: HelpArticleSlug;
  className?: string;
  children: React.ReactNode;
}) {
  function onClick() {
    trackHelpEvent("help_related_click", { from: fromSlug, to: slug });
  }

  return (
    <Link href={`/help/${slug}`} className={className} onClick={onClick}>
      {children}
    </Link>
  );
}
