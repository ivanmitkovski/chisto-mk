import { describe, expect, it } from 'vitest';
import { sanitizeHtmlBlock, sanitizeInlineHtml, sanitizePastedInlineHtml, normalizeInlineLinksInHtml, stripHtmlToPlainText, htmlBlockHasContent } from './html-sanitize';
import { embedProviderFromUrl, embedUrlFromVideoLink, buildEmbedIframeHtml } from './embed-allowlist';
import { plainTextFromBlocks, wordCountFromBlocks } from '../plain-text';
import { sanitizeBodyBlocks, stripEmptyBlocks } from '../migrate-blocks';

describe('sanitizeInlineHtml', () => {
  it('allows links with safe href', () => {
    const out = sanitizeInlineHtml('<p>Click <a href="https://example.com">here</a></p>');
    expect(out).toContain('href="https://example.com"');
    expect(out).toContain('here');
  });

  it('preserves target and rel on saved links', () => {
    const out = sanitizeInlineHtml(
      '<p><a href="https://chisto.mk" target="_blank" rel="noopener noreferrer">Chisto.mk</a></p>',
    );
    expect(out).toContain('href="https://chisto.mk"');
    expect(out).toContain('target="_blank"');
    expect(out).toContain('rel="noopener noreferrer"');
    expect(out).toContain('Chisto.mk');
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

describe('embedProviderFromUrl', () => {
  it('detects youtube and vimeo providers', () => {
    expect(embedProviderFromUrl('https://www.youtube-nocookie.com/embed/abc')).toBe('youtube');
    expect(embedProviderFromUrl('https://player.vimeo.com/video/123')).toBe('vimeo');
    expect(embedProviderFromUrl('https://evil.example/embed')).toBeNull();
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

  it('normalizes watch URLs to youtube-nocookie embed endpoints', () => {
    const html = buildEmbedIframeHtml('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
    expect(html).toContain('https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ');
    expect(html).not.toContain('watch?v=');
  });
});

describe('stripHtmlToPlainText', () => {
  it('removes tags', () => {
    expect(stripHtmlToPlainText('<p>Hello</p>')).toBe('Hello');
  });
});

describe('sanitizePastedInlineHtml', () => {
  it('strips Word cruft while keeping emphasis and links', () => {
    const word = `<!--[if gte mso 9]><xml><o:OfficeDocumentSettings/></xml><![endif]-->
<p class="MsoNormal" style="margin:0cm"><b>Bold</b> and <i>italic</i> with
<a href="https://example.com">a link</a><o:p></o:p></p>
<p class="MsoNormal"><span style="mso-spacerun:yes">&nbsp;</span></p>`;
    const out = sanitizePastedInlineHtml(word);
    expect(out).toContain('<strong>Bold</strong>');
    expect(out).toContain('<em>italic</em>');
    expect(out).toContain('<a href="https://example.com">a link</a>');
    expect(out).not.toContain('MsoNormal');
    expect(out).not.toContain('mso-');
    expect(out).not.toMatch(/<p>(?:\s|&nbsp;)*<\/p>/);
  });

  it('unwraps the Google Docs bold wrapper without bolding everything', () => {
    const gdocs =
      '<b style="font-weight:normal;" id="docs-internal-guid-x"><p><span style="font-weight:700">Strong</span> plain <span style="font-style:italic">slanted</span></p></b>';
    const out = sanitizePastedInlineHtml(gdocs);
    expect(out).toBe('<p><strong>Strong</strong> plain <em>slanted</em></p>');
  });

  it('preserves list structure and downgrades headings to paragraphs', () => {
    const html = '<h2>Title</h2><ul><li>One</li><li>Two</li></ul>';
    const out = sanitizePastedInlineHtml(html);
    expect(out).toBe('<p>Title</p><ul><li>One</li><li>Two</li></ul>');
  });

  it('drops style payloads and scripts entirely', () => {
    const html = '<style>p{color:red}</style><script>alert(1)</script><p>Safe</p>';
    expect(sanitizePastedInlineHtml(html)).toBe('<p>Safe</p>');
  });
});

describe('normalizeInlineLinksInHtml', () => {
  it('strips broken bare chisto.mk anchor links', () => {
    const out = normalizeInlineLinksInHtml('<p><a href="http://Chisto.mk">Chisto.mk</a> exists.</p>');
    expect(out).not.toContain('<a ');
    expect(out).toContain('Chisto.mk exists.');
  });

  it('adds target blank to external https links', () => {
    const out = normalizeInlineLinksInHtml('<p><a href="https://www.chisto.mk/en">site</a></p>');
    expect(out).toContain('target="_blank"');
    expect(out).toContain('https://www.chisto.mk/en');
  });
});

describe('sanitizeBodyBlocks id stability (ADR-1)', () => {
  it('preserves ids provided by the editor and assigns them where missing', () => {
    const out = sanitizeBodyBlocks([
      { id: 'keep-me', type: 'paragraph', text: 'Hello' },
      { type: 'heading', level: 2, text: 'Section' },
    ]);
    expect(out[0]!.id).toBe('keep-me');
    expect(out[1]!.id).toBeTruthy();
  });
});
