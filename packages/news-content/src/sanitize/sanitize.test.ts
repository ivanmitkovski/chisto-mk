import { describe, expect, it } from 'vitest';
import { sanitizeHtmlBlock, sanitizeInlineHtml, stripHtmlToPlainText, htmlBlockHasContent } from './html-sanitize';
import { embedUrlFromVideoLink, buildEmbedIframeHtml } from './embed-allowlist';
import { plainTextFromBlocks, wordCountFromBlocks } from '../plain-text';
import { sanitizeBodyBlocks, stripEmptyBlocks } from '../migrate-blocks';

describe('sanitizeInlineHtml', () => {
  it('allows links with safe href', () => {
    const out = sanitizeInlineHtml('<p>Click <a href="https://example.com">here</a></p>');
    expect(out).toContain('href="https://example.com"');
    expect(out).toContain('here');
  });

  it('strips script tags', () => {
    const out = sanitizeInlineHtml('<script>alert(1)</script><p>ok</p>');
    expect(out).not.toContain('script');
    expect(out).toContain('ok');
  });

  it('strips javascript links', () => {
    const out = sanitizeInlineHtml('<a href="javascript:alert(1)">bad</a>');
    expect(out).not.toContain('javascript:');
  });
});

describe('sanitizeHtmlBlock', () => {
  it('allows youtube iframe', () => {
    const html =
      '<div class="news-embed"><iframe src="https://www.youtube-nocookie.com/embed/abc123" title="x"></iframe></div>';
    const out = sanitizeHtmlBlock(html);
    expect(out).toContain('youtube-nocookie.com/embed/abc123');
    expect(out).toContain('referrerpolicy="strict-origin-when-cross-origin"');
  });

  it('removes untrusted iframe', () => {
    const out = sanitizeHtmlBlock('<iframe src="https://evil.com/x"></iframe>');
    expect(out).not.toContain('evil.com');
  });

  it('detects iframe-only html blocks as non-empty', () => {
    const html = buildEmbedIframeHtml('https://www.youtube-nocookie.com/embed/abc123');
    expect(htmlBlockHasContent(html)).toBe(true);
    expect(stripEmptyBlocks([{ type: 'html', html }])).toHaveLength(1);
  });
});

describe('embedUrlFromVideoLink', () => {
  it('parses youtube watch url', () => {
    expect(embedUrlFromVideoLink('https://www.youtube.com/watch?v=dQw4w9WgXcQ')).toBe(
      'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ',
    );
  });

  it('parses vimeo url', () => {
    expect(embedUrlFromVideoLink('https://vimeo.com/123456')).toBe('https://player.vimeo.com/video/123456');
  });

  it('parses youtube shorts url', () => {
    expect(embedUrlFromVideoLink('https://www.youtube.com/shorts/dQw4w9WgXcQ')).toBe(
      'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ',
    );
  });

  it('adds https scheme when missing', () => {
    expect(embedUrlFromVideoLink('www.youtube.com/watch?v=dQw4w9WgXcQ')).toBe(
      'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ',
    );
  });
});

describe('plainTextFromBlocks', () => {
  it('extracts text from rich paragraph html', () => {
    const text = plainTextFromBlocks([
      { type: 'paragraph', text: 'fallback', html: '<p>Hello <strong>world</strong></p>' },
    ]);
    expect(text).toContain('Hello');
    expect(text).toContain('world');
  });

  it('counts words across block types', () => {
    expect(
      wordCountFromBlocks([
        { type: 'heading', level: 2, text: 'Title Here' },
        { type: 'paragraph', text: 'Two more words' },
      ]),
    ).toBe(5);
  });
});

describe('sanitizeBodyBlocks', () => {
  it('assigns ids and sanitizes html blocks', () => {
    const out = sanitizeBodyBlocks([
      { type: 'paragraph', text: 'Hi', html: '<p>Hi <a href="https://a.com">link</a></p>' },
      { type: 'html', html: '<p>Block</p><script>x</script>' },
    ]);
    expect(out[0].id).toBeTruthy();
    expect(out[1].html).not.toContain('script');
  });

  it('strips empty paragraphs', () => {
    const out = stripEmptyBlocks([
      { type: 'paragraph', text: '  ' },
      { type: 'paragraph', text: 'Keep' },
    ]);
    expect(out).toHaveLength(1);
  });

  it('strips image and video blocks without media id', () => {
    const out = stripEmptyBlocks([
      { type: 'image', mediaId: '' },
      { type: 'video', mediaId: '  ' },
      { type: 'image', mediaId: 'm1' },
    ]);
    expect(out).toEqual([{ type: 'image', mediaId: 'm1' }]);
  });
});

describe('buildEmbedIframeHtml', () => {
  it('builds embed wrapper', () => {
    const html = buildEmbedIframeHtml('https://www.youtube-nocookie.com/embed/x');
    expect(html).toContain('news-embed');
    expect(html).toContain('iframe');
    expect(html).toContain('referrerpolicy="strict-origin-when-cross-origin"');
  });
});

describe('stripHtmlToPlainText', () => {
  it('removes tags', () => {
    expect(stripHtmlToPlainText('<p>Hello</p>')).toBe('Hello');
  });
});
