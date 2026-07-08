import { describe, expect, it } from 'vitest';
import { clipboardToNewsBlocks, summarizeImportedBlocks } from './clipboard-to-blocks';
import { htmlToNewsBlocks } from './html-to-blocks';
import { markdownToNewsBlocks } from './markdown-to-blocks';
import { splitHtmlIntoParagraphBlocks } from './paragraph-from-html';
import { stripPasteMetadata } from './strip-paste-metadata';
import { RELEASE_EN_BODY_MARKDOWN, APP_STORE_URL, PLAY_STORE_URL } from './fixtures/release-en-body';
import { normalizeInlineLinksInHtml } from '../sanitize/html-sanitize';

function stripIds<T extends { id?: string }>(blocks: T[]): Omit<T, 'id'>[] {
  return blocks.map(({ id: _id, ...rest }) => rest);
}

describe('markdownToNewsBlocks', () => {
  it('maps quote, headings, rich ordered list, and bullet links', () => {
    const blocks = markdownToNewsBlocks(RELEASE_EN_BODY_MARKDOWN);
    expect(blocks[0]).toMatchObject({ type: 'quote', text: 'Snap it. Report it. Clean it.' });
    expect(blocks.some((b) => b.type === 'heading' && b.level === 3 && b.text.includes('Thirty seconds'))).toBe(
      true,
    );

    const steps = blocks.find(
      (b) => b.type === 'paragraph' && b.html?.includes('<ol>') && b.html.includes('<strong>'),
    );
    expect(steps).toBeTruthy();

    const storeList = blocks.find(
      (b) => b.type === 'paragraph' && b.html?.includes(APP_STORE_URL) && b.html.includes(PLAY_STORE_URL),
    );
    expect(storeList).toBeTruthy();
    expect(storeList?.html).toContain('target="_blank"');
  });

  it('keeps bare Chisto.mk as plain text in paragraphs', () => {
    const blocks = markdownToNewsBlocks('Chisto.mk exists to help everyone.');
    const paragraph = blocks[0];
    expect(paragraph).toMatchObject({ type: 'paragraph', text: 'Chisto.mk exists to help everyone.' });
    expect(paragraph?.html).toBeUndefined();
  });

  it('creates divider blocks and collapses consecutive dividers', () => {
    const blocks = markdownToNewsBlocks('Line one\n\n---\n\n---\n\nLine two');
    const dividers = blocks.filter((b) => b.type === 'divider');
    expect(dividers).toHaveLength(1);
  });
});

describe('htmlToNewsBlocks', () => {
  it('maps semantic HTML to native blocks', () => {
    const html = `
      <blockquote><p>Tagline</p></blockquote>
      <h3>Section</h3>
      <p>Intro with <a href="https://example.com">link</a>.</p>
      <ol><li><strong>One</strong></li><li>Two</li></ol>
      <hr />
    `;
    const blocks = htmlToNewsBlocks(html);
    expect(blocks[0]).toMatchObject({ type: 'quote', text: 'Tagline' });
    expect(blocks[1]).toMatchObject({ type: 'heading', level: 3, text: 'Section' });
    expect(blocks.some((b) => b.type === 'divider')).toBe(true);
  });
});

describe('clipboardToNewsBlocks', () => {
  it('imports release markdown with expected block mix', () => {
    const result = clipboardToNewsBlocks({ plain: RELEASE_EN_BODY_MARKDOWN });
    expect(result).not.toBeNull();
    expect(result!.source).toBe('markdown');
    expect(result!.blocks.length).toBeGreaterThan(8);

    const summary = summarizeImportedBlocks(result!.blocks);
    expect(summary.quote).toBe(1);
    expect(summary.heading).toBeGreaterThanOrEqual(2);
    expect(summary.divider).toBe(1);
  });

  it('strips CMS metadata labels from pasted release docs', () => {
    const raw = `**TITLE** *(Title field)*
A title

**BODY COPY** *(paste into the article editor)*

---

> **Snap it.**

Body line.`;
    const result = clipboardToNewsBlocks({ plain: raw }, { stripEditorMetadata: true });
    expect(result?.blocks[0]).toMatchObject({ type: 'quote', text: 'Snap it.' });
    expect(result?.blocks.some((b) => b.type === 'paragraph' && b.text.includes('Body line'))).toBe(true);
  });

  it('truncates at maxBlocks', () => {
    const lines = Array.from({ length: 60 }, (_, i) => `Paragraph ${i + 1}`).join('\n\n');
    const result = clipboardToNewsBlocks({ plain: lines }, { maxBlocks: 50 });
    expect(result?.blocks).toHaveLength(50);
    expect(result?.truncated).toBe(true);
  });

  it('falls back to splitHtmlIntoParagraphBlocks for simple HTML', () => {
    const result = clipboardToNewsBlocks({ html: '<p>One</p><p>Two</p>', plain: 'One\nTwo' });
    expect(result?.blocks).toHaveLength(2);
  });
});

describe('stripPasteMetadata', () => {
  it('removes title and SEO sections before body copy', () => {
    const out = stripPasteMetadata(`**TITLE**
My title

**BODY COPY**

> Quote`);
    expect(out).toContain('> Quote');
    expect(out).not.toContain('My title');
  });
});

describe('normalizeInlineLinksInHtml', () => {
  it('removes broken http://Chisto.mk links', () => {
    const out = normalizeInlineLinksInHtml('<p><a href="http://Chisto.mk">Chisto.mk</a> exists.</p>');
    expect(out).not.toContain('<a ');
    expect(out).toContain('Chisto.mk exists.');
  });
});

describe('splitHtmlIntoParagraphBlocks regression', () => {
  it('splits multiple paragraphs into separate blocks', () => {
    const out = splitHtmlIntoParagraphBlocks('<p>One</p><p>Two</p>');
    expect(out).toHaveLength(2);
    expect(stripIds(out)).toEqual([
      { type: 'paragraph', text: 'One' },
      { type: 'paragraph', text: 'Two' },
    ]);
  });
});
