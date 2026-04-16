"use client";

import { useEffect, useRef } from "react";
import { trackHelpEvent } from "@/lib/analytics/track-help";

/** Fires once per full page load when analytics consent is on. */
export function HelpCentreHubAnalytics() {
  const sent = useRef(false);
  useEffect(() => {
    if (sent.current) return;
    sent.current = true;
    trackHelpEvent("help_hub_view");
  }, []);
  return null;
}
