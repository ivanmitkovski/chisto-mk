/** @vitest-environment node */
import { describe, expect, it } from "vitest";
import { renderToStaticMarkup } from "react-dom/server";
import { helpSearchHighlight } from "./help-search-highlight";

describe("helpSearchHighlight", () => {
  it("returns plain text for short query", () => {
    expect(helpSearchHighlight("Hello world", "a")).toBe("Hello world");
  });

  it("highlights multiple words separately", () => {
    const node = helpSearchHighlight("Report a polluted site with photos", "report photo");
    const html = renderToStaticMarkup(<>{node}</>);
    expect(html).toContain("<mark");
    expect(html).toMatch(/Report/);
    expect(html).toMatch(/photo/);
  });

  it("highlights single long token", () => {
    const node = helpSearchHighlight("Troubleshooting offline networks", "offline");
    const html = renderToStaticMarkup(<>{node}</>);
    expect(html).toContain("offline");
    expect(html).toContain("<mark");
  });
});
