const BLOCKED_SCHEMES = /^(javascript|data|vbscript):/i;

/** Normalize a markdown link URL for inline HTML. */
export function normalizeMarkdownLinkUrl(raw: string): string | null {
  const trimmed = raw.trim();
  if (!trimmed || BLOCKED_SCHEMES.test(trimmed)) return null;

  const hasScheme = /^[a-z][a-z0-9+.-]*:/i.test(trimmed);
  const normalized = hasScheme ? trimmed : `https://${trimmed}`;
  if (BLOCKED_SCHEMES.test(normalized)) return null;

  try {
    const parsed = new URL(normalized);
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:' && parsed.protocol !== 'mailto:') {
      return null;
    }
    return normalized;
  } catch {
    return null;
  }
}

function linkAttrs(href: string): string {
  if (href.startsWith('mailto:')) {
    return ` href="${href}"`;
  }
  return ` href="${href}" target="_blank" rel="noopener noreferrer"`;
}

/**
 * Converts a subset of inline markdown to sanitized-ready HTML fragments.
 * Does not autolink bare domains (e.g. Chisto.mk).
 */
export function inlineMarkdownToHtml(text: string): string {
  let out = text;

  // Links first so emphasis parsers do not touch URL segments.
  out = out.replace(/\[([^\]]+)\]\(([^)]+)\)/g, (_match, label: string, url: string) => {
    const href = normalizeMarkdownLinkUrl(url);
    if (!href) return label;
    return `<a${linkAttrs(href)}>${inlineMarkdownToHtml(label)}</a>`;
  });

  out = out.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
  out = out.replace(/__([^_]+)__/g, '<strong>$1</strong>');
  out = out.replace(/(?<!\*)\*([^*]+)\*(?!\*)/g, '<em>$1</em>');
  out = out.replace(/(?<!_)_([^_]+)_(?!_)/g, '<em>$1</em>');

  return out;
}

export function stripInlineMarkdown(text: string): string {
  return text
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
    .replace(/\*\*([^*]+)\*\*/g, '$1')
    .replace(/__([^_]+)__/g, '$1')
    .replace(/(?<!\*)\*([^*]+)\*(?!\*)/g, '$1')
    .replace(/(?<!_)_([^_]+)_(?!_)/g, '$1');
}

export function listItemHasInlineMarkup(item: string): boolean {
  return (
    /\*\*[^*]+\*\*/.test(item) ||
    /__[^_]+__/.test(item) ||
    /\[([^\]]+)\]\([^)]+\)/.test(item) ||
    /(?<!\*)\*[^*]+\*(?!\*)/.test(item)
  );
}
