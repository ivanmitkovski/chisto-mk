"use client";

import type { ComponentProps } from "react";
import { Link } from "@/i18n/routing";
import { trackNewsEvent } from "@/lib/analytics/track-news";

type NewsRelatedAnalyticsLinkProps = ComponentProps<typeof Link> & {
  slug: string;
  fromSlug: string;
};

export function NewsRelatedAnalyticsLink({
  slug,
  fromSlug,
  onClick,
  ...props
}: NewsRelatedAnalyticsLinkProps) {
  return (
    <Link
      {...props}
      onClick={(e) => {
        trackNewsEvent("news_related_click", { slug, from_slug: fromSlug });
        onClick?.(e);
      }}
    />
  );
}
