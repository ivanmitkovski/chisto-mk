import { Transform } from 'class-transformer';
import { sanitizePlainText } from './sanitize-html.util';

/** Strips HTML from string DTO fields (UGC plain-text policy). */
export function SanitizePlainText() {
  return Transform(({ value }) => {
    if (typeof value !== 'string') return value;
    return sanitizePlainText(value);
  });
}
