import type { NewsBodyBlock } from '@chisto/news-content';

export type ClipboardImportPayload = {
  html: string;
  plain: string;
};

/** True when imported blocks carry document structure beyond a single plain paragraph. */
export function isStructuredImport(blocks: NewsBodyBlock[]): boolean {
  if (blocks.length > 1) return true;
  const first = blocks[0];
  if (!first) return false;
  return first.type !== 'paragraph' || Boolean(first.html?.trim());
}

/** Reads clipboard text/html for structured body import. Returns null when access is denied. */
export async function readClipboardForImport(): Promise<ClipboardImportPayload | null> {
  if (typeof navigator === 'undefined' || !navigator.clipboard) {
    return null;
  }

  // Clipboard API requires a focused document; toolbar clicks can steal focus first.
  if (typeof window !== 'undefined' && typeof window.focus === 'function') {
    window.focus();
  }

  let plain = '';
  try {
    plain = await navigator.clipboard.readText();
  } catch {
    return null;
  }

  let html = '';
  try {
    const items = await navigator.clipboard.read();
    for (const item of items) {
      if (!item.types.includes('text/html')) continue;
      html = await (await item.getType('text/html')).text();
      break;
    }
  } catch {
    // text/plain is enough for markdown paste; HTML is optional.
  }

  if (!plain.trim() && !html.trim()) {
    return null;
  }

  return { html, plain };
}
