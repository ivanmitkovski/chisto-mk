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

function escapeHtmlAttr(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function linkAttrs(href: string): string {
  const safeHref = escapeHtmlAttr(href);
  if (href.startsWith('mailto:')) {
    return ` href="${safeHref}"`;
  }
  return ` href="${safeHref}" target="_blank" rel="noopener noreferrer"`;
}

function findMarkdownLinkAt(
  text: string,
  start: number,
): { label: string; url: string; end: number } | null {
  if (text[start] !== '[') return null;
  const closeBracket = text.indexOf(']', start + 1);
  if (closeBracket === -1 || text[closeBracket + 1] !== '(') return null;
  const closeParen = text.indexOf(')', closeBracket + 2);
  if (closeParen === -1) return null;
  return {
    label: text.slice(start + 1, closeBracket),
    url: text.slice(closeBracket + 2, closeParen),
    end: closeParen + 1,
  };
}

function replaceMarkdownLinks(
  text: string,
  replacer: (label: string, url: string) => string,
): string {
  let result = '';
  let i = 0;
  while (i < text.length) {
    const link = findMarkdownLinkAt(text, i);
    if (link) {
      result += replacer(link.label, link.url);
      i = link.end;
      continue;
    }
    result += text[i];
    i += 1;
  }
  return result;
}

function replaceDelimited(
  text: string,
  open: string,
  close: string,
  wrap: (inner: string) => string,
): string {
  let result = '';
  let i = 0;
  while (i < text.length) {
    if (text.startsWith(open, i)) {
      const end = text.indexOf(close, i + open.length);
      if (end !== -1) {
        result += wrap(text.slice(i + open.length, end));
        i = end + close.length;
        continue;
      }
    }
    result += text[i];
    i += 1;
  }
  return result;
}

function replaceSingleDelimited(
  text: string,
  delimiter: string,
  openTag: string,
  closeTag: string,
): string {
  let result = '';
  let i = 0;
  while (i < text.length) {
    if (text[i] === delimiter) {
      if (text[i + 1] === delimiter) {
        result += text[i];
        i += 1;
        continue;
      }
      const end = text.indexOf(delimiter, i + 1);
      if (end !== -1 && text[end + 1] !== delimiter) {
        result += `${openTag}${text.slice(i + 1, end)}${closeTag}`;
        i = end + 1;
        continue;
      }
    }
    result += text[i];
    i += 1;
  }
  return result;
}

/** True when text contains a `[label](url)` markdown link. */
export function hasMarkdownLink(text: string): boolean {
  let i = 0;
  while (i < text.length) {
    if (findMarkdownLinkAt(text, i)) return true;
    i += 1;
  }
  return false;
}

/**
 * Converts a subset of inline markdown to sanitized-ready HTML fragments.
 * Does not autolink bare domains (e.g. Chisto.mk).
 */
export function inlineMarkdownToHtml(text: string): string {
  let out = replaceMarkdownLinks(text, (label, url) => {
    const href = normalizeMarkdownLinkUrl(url);
    if (!href) return label;
    return `<a${linkAttrs(href)}>${inlineMarkdownToHtml(label)}</a>`;
  });

  out = replaceDelimited(out, '**', '**', (inner) => `<strong>${inner}</strong>`);
  out = replaceDelimited(out, '__', '__', (inner) => `<strong>${inner}</strong>`);
  out = replaceSingleDelimited(out, '*', '<em>', '</em>');
  out = replaceSingleDelimited(out, '_', '<em>', '</em>');

  return out;
}

export function stripInlineMarkdown(text: string): string {
  let out = replaceMarkdownLinks(text, (label) => label);
  out = replaceDelimited(out, '**', '**', (inner) => inner);
  out = replaceDelimited(out, '__', '__', (inner) => inner);
  out = replaceSingleDelimited(out, '*', '', '');
  out = replaceSingleDelimited(out, '_', '', '');
  return out;
}

export function listItemHasInlineMarkup(item: string): boolean {
  if (item.includes('**') || item.includes('__')) return true;
  if (hasMarkdownLink(item)) return true;
  for (let i = 0; i < item.length; i += 1) {
    if (item[i] === '*' && item[i + 1] !== '*') return true;
    if (item[i] === '_' && item[i + 1] !== '_') return true;
  }
  return false;
}
