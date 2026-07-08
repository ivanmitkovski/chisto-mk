import { describe, expect, it, vi, afterEach } from 'vitest';
import { clipboardToNewsBlocks } from '@chisto/news-content';
import { isStructuredImport, readClipboardForImport } from './news-structured-paste';

describe('news structured paste helpers', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('detects structured imports with multiple blocks', () => {
    const result = clipboardToNewsBlocks({
      plain: '> Quote\n\n### Heading\n\nParagraph text.',
    });
    expect(result).not.toBeNull();
    expect(isStructuredImport(result!.blocks)).toBe(true);
  });

  it('treats a single plain paragraph as unstructured', () => {
    expect(isStructuredImport([{ type: 'paragraph', text: 'Only one line.' }])).toBe(false);
  });

  it('returns null when clipboard read is denied', async () => {
    vi.stubGlobal('navigator', {
      clipboard: {
        readText: vi.fn().mockRejectedValue(new DOMException('denied', 'NotAllowedError')),
        read: vi.fn(),
      },
    });
    await expect(readClipboardForImport()).resolves.toBeNull();
  });

  it('reads plain text first and treats html as optional', async () => {
    vi.stubGlobal('navigator', {
      clipboard: {
        readText: vi.fn().mockResolvedValue('> Quote'),
        read: vi.fn().mockRejectedValue(new DOMException('denied', 'NotAllowedError')),
      },
    });
    await expect(readClipboardForImport()).resolves.toEqual({ html: '', plain: '> Quote' });
  });
});
