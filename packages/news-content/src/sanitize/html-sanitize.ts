import sanitizeHtml from 'sanitize-html';
import { isAllowedEmbedUrl } from './embed-allowlist';

const INLINE_ALLOWED_TAGS = ['p', 'a', 'strong', 'em', 'u', 'br', 'ul', 'ol', 'li'];

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

function stripUntrustedIframes(html: string): string {
  return html.replace(/<iframe\b[^>]*\ssrc=["']([^"']+)["'][^>]*>(?:\s*<\/iframe>)?/gi, (full, src: string) => {
    return isAllowedEmbedUrl(src) ? full : '';
  });
}

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
  const sanitized = sanitizeHtml(html, {
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
    transformTags: {
      iframe: (_tagName, attribs) => {
        const src = attribs.src ?? '';
        if (!isAllowedEmbedUrl(src)) {
          return { tagName: 'iframe', attribs: {} };
        }
        return {
          tagName: 'iframe',
          attribs: {
            ...attribs,
            referrerpolicy: 'strict-origin-when-cross-origin',
          },
        };
      },
    },
  });

  return stripUntrustedIframes(sanitized).trim();
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
