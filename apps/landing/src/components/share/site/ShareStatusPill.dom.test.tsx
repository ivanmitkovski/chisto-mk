/** @vitest-environment jsdom */
import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { ShareStatusPill } from "./ShareStatusPill";
import {
  formatCleanupEffort,
  formatReportCategory,
  formatSeverity,
  formatSiteStatus,
} from "@/app/sites/[id]/site-share-strings";

describe("site share formatters", () => {
  it("formats site status in mk and en", () => {
    expect(formatSiteStatus("VERIFIED", "mk")).toBe("Потврдено");
    expect(formatSiteStatus("CLEANED", "en")).toBe("Cleaned");
  });

  it("formats category, severity, and cleanup effort", () => {
    expect(formatReportCategory("ILLEGAL_LANDFILL", "en")).toBe("Illegal landfill");
    expect(formatSeverity(3, "en")).toBe("3, Significant");
    expect(formatCleanupEffort("THREE_TO_FIVE", "en")).toBe("3-5 people");
  });

  it("returns empty strings for missing optional fields", () => {
    expect(formatReportCategory(null, "en")).toBe("");
    expect(formatSeverity(null, "en")).toBe("");
    expect(formatCleanupEffort(undefined, "en")).toBe("");
  });
});

describe("ShareStatusPill", () => {
  it("renders the status label", () => {
    render(<ShareStatusPill status="VERIFIED" label="Verified" />);
    expect(screen.getByText("Verified")).toBeTruthy();
  });
});
