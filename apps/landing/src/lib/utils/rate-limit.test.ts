import { describe, expect, it } from "vitest";
import { checkRateLimit } from "./rate-limit";

describe("checkRateLimit", () => {
  it("allows requests under the limit", () => {
    const key = `test-${Date.now()}`;
    expect(checkRateLimit(key)).toBe(true);
    expect(checkRateLimit(key)).toBe(true);
  });
});
