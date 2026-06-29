import { describe, expect, it } from "vitest";
import { HELP_ARTICLE_SLUGS } from "./help-catalog";
import { HELP_MOBILE_FLOW_COVERAGE, assertHelpMobileFlowCoverage } from "./help-terminology";

describe("help mobile flow coverage", () => {
  it("maps every flow group to at least one published article slug", () => {
    expect(() => assertHelpMobileFlowCoverage()).not.toThrow();
    for (const slugs of Object.values(HELP_MOBILE_FLOW_COVERAGE)) {
      expect(slugs.length).toBeGreaterThan(0);
      for (const slug of slugs) {
        expect(HELP_ARTICLE_SLUGS).toContain(slug);
      }
    }
  });

  it("covers all major mobile domains", () => {
    expect(Object.keys(HELP_MOBILE_FLOW_COVERAGE).sort()).toEqual(
      [
        "auth",
        "eventChatCheckIn",
        "eventsHost",
        "eventsJoin",
        "feed",
        "map",
        "notifications",
        "offline",
        "onboarding",
        "organisations",
        "permissions",
        "pointsGamification",
        "profile",
        "reportLifecycle",
        "reporting",
        "safety",
        "troubleshooting",
      ].sort(),
    );
  });
});
