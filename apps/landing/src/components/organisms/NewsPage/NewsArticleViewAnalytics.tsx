"use client";

import { useEffect, useRef } from "react";
import { trackNewsEvent } from "@/lib/analytics/track-news";

export function NewsArticleViewAnalytics({ slug }: { slug: string }) {
  const sent = useRef(false);
  useEffect(() => {
    if (sent.current) return;
    sent.current = true;
    trackNewsEvent("news_article_view", { slug });
  }, [slug]);
  return null;
}
