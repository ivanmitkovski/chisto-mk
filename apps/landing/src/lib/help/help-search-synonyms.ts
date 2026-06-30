/** Search synonym expansions (query token → extra terms folded into haystack). */
export const HELP_SEARCH_SYNONYMS: Record<string, readonly string[]> = {
  otp: ["verification", "code", "sms", "sign-in"],
  qr: ["check-in", "checkin", "scan"],
  heatmap: ["map", "layer"],
  draft: ["resume", "offline", "outbox"],
  points: ["rankings", "leaderboard", "levels"],
  password: ["sign-in", "forgot", "reset"],
  notification: ["push", "alert", "inbox"],
  report: ["pollution", "wizard", "fab"],
  chat: ["message", "event"],
  block: ["safety", "user"],
  location: ["gps", "permission", "macedonia"],
  credits: ["capacity", "cooldown"],
};

export function expandHelpSearchQuery(query: string): string {
  const words = query.toLowerCase().split(/\s+/).filter(Boolean);
  const extras: string[] = [];
  for (const word of words) {
    const syn = HELP_SEARCH_SYNONYMS[word];
    if (syn) extras.push(...syn);
  }
  return extras.length > 0 ? `${query} ${extras.join(" ")}` : query;
}
