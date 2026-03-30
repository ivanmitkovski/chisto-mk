import { describe, expect, it } from "vitest";
import { escapeHtml } from "./escape-html";

describe("escapeHtml", () => {
  it("escapes special characters", () => {
    expect(escapeHtml(`<&>"'`)).toBe("&lt;&amp;&gt;&quot;&#39;");
  });

  it("leaves plain text", () => {
    expect(escapeHtml("hello")).toBe("hello");
  });
});
