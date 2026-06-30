import type { HelpArticleSlug } from "./help-catalog";

/**
 * Canonical in-app labels used across help articles (English reference).
 * Keep aligned with mobile l10n and landing marketing copy.
 */
export const HELP_TERMINOLOGY_EN = {
  tabs: {
    feed: "Home",
    reports: "Reports",
    map: "Map",
    events: "Events",
  },
  actions: {
    reportFab: "Report",
    takeAction: "Take action",
    joinEcoAction: "Join eco-action",
    download: "Download",
  },
  reportStages: {
    evidence: "Evidence",
    details: "Details",
    location: "Location",
    review: "Review",
  },
  reportCategories: {
    illegalLandfill: "Illegal landfill",
    waterPollution: "Water pollution",
    airPollution: "Air pollution",
    industrialWaste: "Industrial waste",
    other: "Other",
  },
  reportStatuses: {
    underReview: "Under review",
    approved: "Approved",
    declined: "Declined",
    alreadyReported: "Already reported",
  },
  feedFilters: {
    all: "All",
    urgent: "Urgent",
    nearby: "Nearby",
    mostVoted: "Most voted",
    recent: "Recent",
    saved: "Saved",
    resolved: "Resolved",
  },
  notificationGroups: [
    "Site updates",
    "Report status",
    "Upvotes",
    "Comments",
    "Nearby reports",
    "Cleanup events",
    "Event chat",
    "System",
  ],
} as const;

/** Mobile user-flow groups that must map to at least one help article. */
export type HelpMobileFlowGroup =
  | "onboarding"
  | "auth"
  | "permissions"
  | "feed"
  | "map"
  | "reporting"
  | "reportLifecycle"
  | "eventsJoin"
  | "eventsHost"
  | "eventChatCheckIn"
  | "profile"
  | "pointsGamification"
  | "notifications"
  | "safety"
  | "offline"
  | "troubleshooting"
  | "organisations";

/** Editorial mapping: every mobile flow group → one or more article slugs. */
export const HELP_MOBILE_FLOW_COVERAGE: Record<HelpMobileFlowGroup, readonly HelpArticleSlug[]> = {
  onboarding: ["getting-started", "sign-in-and-verification"],
  auth: ["sign-in-and-verification", "troubleshooting"],
  permissions: ["app-permissions", "troubleshooting"],
  feed: ["home-feed-and-sites"],
  map: ["exploring-the-map", "home-feed-and-sites"],
  reporting: ["report-a-site", "app-permissions"],
  reportLifecycle: ["report-statuses-and-drafts", "report-a-site"],
  eventsJoin: ["join-a-cleanup-event", "event-check-in-and-chat"],
  eventsHost: ["hosting-a-cleanup-event", "event-check-in-and-chat"],
  eventChatCheckIn: ["event-check-in-and-chat"],
  profile: ["your-profile-and-settings", "account-and-data"],
  pointsGamification: ["points-rankings-and-credits"],
  notifications: ["notifications-in-the-app"],
  safety: ["trust-safety-and-moderation"],
  offline: ["offline-and-slow-networks", "report-statuses-and-drafts"],
  troubleshooting: ["troubleshooting", "app-permissions"],
  organisations: ["partnerships-for-organisations"],
};

export function assertHelpMobileFlowCoverage(): void {
  for (const [group, slugs] of Object.entries(HELP_MOBILE_FLOW_COVERAGE)) {
    if (slugs.length === 0) {
      throw new Error(`Help mobile flow group "${group}" has no article mapping`);
    }
  }
}
