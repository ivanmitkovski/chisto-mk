"use client";

import { track } from "@vercel/analytics";
import { analyticsOptIn } from "@/lib/analytics/analytics-opt-in";

export function trackNewsEvent(
  name: string,
  properties?: Record<string, string | number | boolean | null | undefined>,
) {
  if (!analyticsOptIn()) return;
  track(name, properties);
}
