import sanitizeHtml from 'sanitize-html';

const PLAIN_TEXT_OPTIONS: sanitizeHtml.IOptions = {
  allowedTags: [],
  allowedAttributes: {},
  disallowedTagsMode: 'discard',
};

export function sanitizePlainText(input: string): string {
  return sanitizeHtml(input, PLAIN_TEXT_OPTIONS).trim();
}
