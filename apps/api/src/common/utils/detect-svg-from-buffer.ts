/**
 * Detect SVG from buffer content (not MIME). Rejects obvious non-SVG prefixes.
 */
export function detectSvgFromBuffer(buf: Buffer): boolean {
  const sample = buf
    .toString('utf8', 0, Math.min(buf.length, 8192))
    .replace(/^\uFEFF/, '')
    .trimStart();

  if (!sample) {
    return false;
  }

  const lower = sample.slice(0, 256).toLowerCase();
  if (lower.startsWith('<!doctype html') || lower.startsWith('<html')) {
    return false;
  }

  if (lower.startsWith('<svg')) {
    return true;
  }

  if (lower.startsWith('<?xml')) {
    return /<svg[\s>/]/i.test(sample);
  }

  return false;
}
