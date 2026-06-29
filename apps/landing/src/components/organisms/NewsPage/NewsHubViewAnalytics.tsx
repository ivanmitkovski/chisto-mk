"use client";

import { useEffect, useRef } from "react";
import { trackNewsEvent } from "@/lib/analytics/track-news";

export function NewsHubViewAnalytics() {
  const sent = useRef(false);
  useEffect(() => {
    if (sent.current) return;
    sent.current = true;
    trackNewsEvent("news_hub_view");
  }, []);
  return null;
}
