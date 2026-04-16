import { Fragment, type ReactNode } from "react";

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/**
 * Wraps substring matches in subtle `<mark>` for search results.
 * Words are taken from the query (length at least 2); each word is highlighted separately.
 */
export function helpSearchHighlight(text: string, query: string): ReactNode {
  const q = query.trim();
  if (q.length < 2) {
    return text;
  }
  const words = q.split(/\s+/).map((w) => w.trim()).filter((w) => w.length >= 2);
  if (words.length === 0) {
    return text;
  }
  const pattern = words.map(escapeRegExp).join("|");
  const re = new RegExp(`(${pattern})`, "gi");
  const parts = text.split(re);
  return parts.map((part, i) =>
    i % 2 === 1 ? (
      <mark key={i} className="rounded-sm bg-primary/15 px-0.5 font-[inherit] text-inherit">
        {part}
      </mark>
    ) : (
      <Fragment key={i}>{part}</Fragment>
    ),
  );
}
