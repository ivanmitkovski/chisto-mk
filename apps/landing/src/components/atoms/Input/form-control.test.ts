import { describe, expect, it } from "vitest";
import { formControlClassName } from "./form-control";

describe("formControlClassName", () => {
  it("uses text-base so iOS Safari does not zoom on focus (<16px)", () => {
    expect(formControlClassName).toContain("text-base");
    expect(formControlClassName).not.toMatch(/\btext-sm\b/);
    expect(formControlClassName).not.toMatch(/\btext-xs\b/);
  });
});
