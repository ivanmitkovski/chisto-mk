import sanitizeHtml from 'sanitize-html';
import { isAllowedEmbedUrl } from './embed-allowlist';

const INLINE_ALLOWED_TAGS = ['p', 'a', 'strong', 'em', 'u', 'br', 'ul', 'ol', 'li'];

const IMPORT_ALLOWED_TAGS = [
  'h2',
  'h3',
  'blockquote',
  'hr',
  'p',
  'ul',
  'ol',
  'li',
  'div',
  'a',
  'strong',
  'em',
  'u',
  'br',
  'b',
  'i',
  'span',
];

const HTML_BLOCK_ALLOWED_TAGS = [
  'p',
  'div',
  'span',
  'h2',
  'h3',
  'blockquote',
  'ul',
  'ol',
  'li',
  'a',
  'strong',
  'em',
  'u',
  'br',
  'figure',
  'figcaption',
  'iframe',
];

export function sanitizeInlineHtml(html: string): string {
  return sanitizeHtml(html, {
    allowedTags: INLINE_ALLOWED_TAGS,
    allowedAttributes: {
      a: ['href', 'target', 'rel'],
    },
    allowedSchemes: ['http', 'https', 'mailto'],
    disallowedTagsMode: 'discard',
  }).trim();
}

export function sanitizeHtmlBlock(html: string): string {
  return sanitizeHtml(html, {
    allowedTags: HTML_BLOCK_ALLOWED_TAGS,
    allowedAttributes: {
      a: ['href', 'target', 'rel'],
      iframe: ['src', 'title', 'loading', 'allow', 'allowfullscreen', 'frameborder', 'referrerpolicy'],
      div: ['class'],
      span: ['class'],
    },
    allowedSchemes: ['http', 'https'],
    allowedClasses: {
      div: ['news-embed'],
    },
    disallowedTagsMode: 'discard',
    exclusiveFilter: (frame) => {
      if (frame.tag === 'iframe') {
        return !isAllowedEmbedUrl(frame.attribs.src ?? '');
      }
      return false;
    },
    transformTags: {
      iframe: (_tagName: string, attribs: Record<string, string>) => ({
        tagName: 'iframe',
        attribs: {
          ...attribs,
          referrerpolicy: 'strict-origin-when-cross-origin',
        },
      }),
    },
  }).trim();
}

/**
 * Cleans HTML pasted from Word / Google Docs / other editors down to the
 * inline allowlist, preserving semantic emphasis and list/link structure:
 * - drops comments, <style>/<script> payloads, mso-* junk
 * - maps <b>/<i> (and Google Docs font-weight spans) to <strong>/<em>
 * - unwraps headings/divs into paragraphs so text is never lost
 */
export function sanitizePastedInlineHtml(html: string): string {
  const sanitized = sanitizeHtml(html, {
    allowedTags: INLINE_ALLOWED_TAGS,
    allowedAttributes: {
      a: ['href', 'target', 'rel'],
    },
    allowedSchemes: ['http', 'https', 'mailto'],
    disallowedTagsMode: 'discard',
    transformTags: {
      // Google Docs wraps the whole clipboard in <b style="font-weight:normal">.
      b: (_tagName: string, attribs: Record<string, string>) => {
        if (/font-weight\s*:\s*(normal|[1-4]00)/i.test(attribs.style ?? '')) {
          return { tagName: 'span', attribs: {} };
        }
        return { tagName: 'strong', attribs: {} };
      },
      i: 'em',
      h1: 'p',
      h2: 'p',
      h3: 'p',
      h4: 'p',
      h5: 'p',
      h6: 'p',
      div: 'p',
      span: (_tagName: string, attribs: Record<string, string>) => {
        const style = attribs.style ?? '';
        if (/font-weight\s*:\s*(bold|[6-9]00)/i.test(style)) {
          return { tagName: 'strong', attribs: {} };
        }
        if (/font-style\s*:\s*italic/i.test(style)) {
          return { tagName: 'em', attribs: {} };
        }
        return { tagName: 'span', attribs: {} };
      },
    },
  });
  // Collapse paragraphs that ended up empty after stripping Word artifacts.
  return sanitized
    .replace(/<p>(?:\s|&nbsp;|<br\s*\/?>)*<\/p>/gi, '')
    .replace(/<p><\/p>/gi, '')
    .trim();
}

/**
 * Sanitizes clipboard HTML for structured import while preserving block-level
 * semantics (headings, quotes, dividers) before mapping to NewsBodyBlock types.
 */
export function sanitizeImportHtml(html: string): string {
  return sanitizeHtml(html, {
    allowedTags: IMPORT_ALLOWED_TAGS,
    allowedAttributes: {
      a: ['href', 'target', 'rel'],
    },
    allowedSchemes: ['http', 'https', 'mailto'],
    disallowedTagsMode: 'discard',
    transformTags: {
      b: 'strong',
      i: 'em',
      h1: 'h2',
      h4: 'h3',
      h5: 'h3',
      h6: 'h3',
      span: (_tagName: string, attribs: Record<string, string>) => {
        const style = attribs.style ?? '';
        if (/font-weight\s*:\s*(bold|[6-9]00)/i.test(style)) {
          return { tagName: 'strong', attribs: {} };
        }
        if (/font-style\s*:\s*italic/i.test(style)) {
          return { tagName: 'em', attribs: {} };
        }
        return { tagName: 'span', attribs: {} };
      },
    },
  })
    .replace(/<p>(?:\s|&nbsp;|<br\s*\/?>)*<\/p>/gi, '')
    .trim();
}

const BARE_DOMAIN_LINK = /^https?:\/\/chisto\.mk\/?$/i;

/** Strips broken bare-domain links and normalizes external anchors in paragraph HTML. */
export function normalizeInlineLinksInHtml(html: string): string {
  return sanitizeInlineHtml(html).replace(
    /<a\b([^>]*?)href=["']([^"']+)["']([^>]*)>([\s\S]*?)<\/a>/gi,
    (_full, _before: string, href: string, _after: string, label: string) => {
      if (BARE_DOMAIN_LINK.test(href) || /^https?:\/\/Chisto\.mk\/?$/i.test(href)) {
        return label;
      }
      let normalizedHref = href;
      if (!/^[a-z][a-z0-9+.-]*:/i.test(href)) {
        try {
          normalizedHref = new URL(`https://${href}`).href;
        } catch {
          return label;
        }
      }
      if (normalizedHref.startsWith('mailto:')) {
        return `<a href="${normalizedHref}">${label}</a>`;
      }
      return `<a href="${normalizedHref}" target="_blank" rel="noopener noreferrer">${label}</a>`;
    },
  );
}

export function stripHtmlToPlainText(html: string): string {
  return sanitizeHtml(html, { allowedTags: [], allowedAttributes: {} }).trim();
}

export function hasVisibleText(value: string): boolean {
  return stripHtmlToPlainText(value).length > 0;
}

/** True when an HTML block has copy and/or an allowed iframe embed. */
export function htmlBlockHasContent(html: string): boolean {
  const trimmed = html?.trim() ?? '';
  if (!trimmed) return false;
  if (hasVisibleText(trimmed)) return true;
  return /<iframe\b/i.test(sanitizeHtmlBlock(trimmed));
}
