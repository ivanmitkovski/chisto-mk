export type PublicStatItem = {
  number: string;
  labelKey: "reports" | "sites" | "events" | "appStore";
};

export type PublicStatsPayload = {
  asOf: string;
  items: PublicStatItem[];
};

/** Curated launch metrics — replace with API fetch when admin endpoint is ready. */
export const PUBLIC_STATS: PublicStatsPayload = {
  asOf: "2026-06-01",
  items: [
    { number: "2,400+", labelKey: "reports" },
    { number: "680+", labelKey: "sites" },
    { number: "120+", labelKey: "events" },
    { number: "Free", labelKey: "appStore" },
  ],
};

export function getPublicStats(): PublicStatsPayload {
  return PUBLIC_STATS;
}
