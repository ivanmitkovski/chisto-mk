import { describe, expect, it } from "vitest";
import {
  APPLE_BADGE_HEIGHT_PX,
  GOOGLE_BADGE_BLEED_X_RATIO,
  GOOGLE_BADGE_WIDTH_PX,
  STORE_BADGE_ROW_HEIGHT_MD_PX,
  STORE_BADGE_ROW_HEIGHT_PX,
  googleBadgeVisibleWidthPx,
} from "./store-badges";

describe("store-badges", () => {
  it("uses a row height that compensates for Google Play PNG bleed padding", () => {
    // Google visible button is ~68% of file height; 58px slot ≈ 39px visible vs Apple 40px.
    const googleVisibleHeight = STORE_BADGE_ROW_HEIGHT_PX * (170 / 250);
    expect(googleVisibleHeight).toBeGreaterThanOrEqual(APPLE_BADGE_HEIGHT_PX - 1);
    expect(googleVisibleHeight).toBeLessThanOrEqual(APPLE_BADGE_HEIGHT_PX + 1);
  });

  it("keeps Google Play badge width proportional at row height", () => {
    expect(GOOGLE_BADGE_WIDTH_PX).toBe(Math.round((646 / 250) * STORE_BADGE_ROW_HEIGHT_PX));
  });

  it("documents symmetric horizontal bleed in Google Play PNG assets", () => {
    expect(GOOGLE_BADGE_BLEED_X_RATIO).toBeCloseTo(0.0635, 4);
  });

  it("computes cropped Google Play badge width from row height", () => {
    expect(googleBadgeVisibleWidthPx(STORE_BADGE_ROW_HEIGHT_PX)).toBe(131);
    expect(googleBadgeVisibleWidthPx(STORE_BADGE_ROW_HEIGHT_MD_PX)).toBe(144);
  });
});
