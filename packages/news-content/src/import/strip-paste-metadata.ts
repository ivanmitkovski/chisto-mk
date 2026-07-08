const CMS_FIELD_HINT = /^\*\([^)]*(?:field|поле|fushë)[^)]*\)\*?$/i;
const META_LINE = /^-\s*Meta\s/i;
const BODY_COPY_MARKER = /^\*\*BODY COPY\*\*/i;

/** Strips CMS authoring labels and wrapper noise from pasted release copy. */
export function stripPasteMetadata(text: string): string {
  const lines = text.replace(/\r\n/g, '\n').split('\n');
  const hasBodyMarker = lines.some((line) => BODY_COPY_MARKER.test(line.trim()) || /paste into the article editor/i.test(line.trim()));
  if (!hasBodyMarker) {
    return text.trim();
  }

  const filtered: string[] = [];
  let inBody = false;

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || /^<br\s*\/?>$/i.test(trimmed)) continue;
    if (/^How to use this file/i.test(trimmed)) continue;
    if (/^Shared CMS fields/i.test(trimmed)) continue;
    if (/^Store links/i.test(trimmed)) continue;
    if (CMS_FIELD_HINT.test(trimmed)) continue;
    if (META_LINE.test(trimmed)) continue;
    if (/^\*\*(TITLE|EXCERPT|SEO)\*\*/i.test(trimmed)) continue;
    if (BODY_COPY_MARKER.test(trimmed) || /paste into the article editor/i.test(trimmed)) {
      inBody = true;
      continue;
    }
    if (/^#\s+(ENGLISH|МАКЕДОНСКИ|SHQIP)/i.test(trimmed)) continue;
    if (/^Publish date:|^Category:|^Slug:|^Featured:|^Cover:/i.test(trimmed)) continue;
    if (/^App Store:|^Google Play:/i.test(trimmed)) continue;
    if (!inBody) continue;
    if (trimmed === '---' && filtered.length === 0) continue;

    filtered.push(line);
  }

  let result = filtered.join('\n').trim();
  result = result.replace(/^---\s*\n/, '').replace(/\n---\s*$/, '').trim();
  return result;
}
