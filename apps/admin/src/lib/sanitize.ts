import DOMPurify from 'isomorphic-dompurify';

/**
 * SECURITY: Strip all HTML from user-controlled strings before rendering in rich contexts
 * (tooltips, map labels, or future dangerouslySetInnerHTML). React text nodes escape `{x}` but
 * this is the belt-and-suspenders layer for markup-bearing fields from the API.
 */
export function sanitizeDisplayText(value: string): string {
  return DOMPurify.sanitize(value, { ALLOWED_TAGS: [] });
}
