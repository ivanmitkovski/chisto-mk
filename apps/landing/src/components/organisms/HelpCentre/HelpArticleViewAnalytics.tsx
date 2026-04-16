"use client";

import { useEffect, useRef } from "react";
import { trackHelpEvent } from "@/lib/analytics/track-help";
import type { HelpArticleSlug } from "@/lib/help/help-catalog";

export function HelpArticleViewAnalytics({ slug }: { slug: HelpArticleSlug }) {
  const sent = useRef(false);
  useEffect(() => {
    if (sent.current) return;
    sent.current = true;
    trackHelpEvent("help_article_view", { slug });
  }, [slug]);
  return null;
}
