import type { EnrichedGalleryBlock, EnrichedGalleryItem, NewsBodyBlock, ResolvedNewsBodyBlock } from './types';
import { sanitizeHtmlBlock, sanitizeInlineHtml } from './sanitize/html-sanitize';
import { buildEmbedIframeHtml } from './sanitize/embed-allowlist';

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

export function blocksToEncodedHtml(blocks: readonly (NewsBodyBlock | ResolvedNewsBodyBlock)[]): string {
  const parts: string[] = [];

  for (const block of blocks) {
    switch (block.type) {
      case 'paragraph': {
        const html = block.html?.trim();
        if (html) {
          parts.push(sanitizeInlineHtml(html));
        } else if (block.text.trim()) {
          parts.push(`<p>${escapeHtml(block.text.trim())}</p>`);
        }
        break;
      }
      case 'html': {
        const safe = sanitizeHtmlBlock(block.html);
        if (safe) parts.push(safe);
        break;
      }
      case 'heading': {
        const text = block.text.trim();
        if (text) {
          const tag = block.level === 3 ? 'h3' : 'h2';
          parts.push(`<${tag}>${escapeHtml(text)}</${tag}>`);
        }
        break;
      }
      case 'list': {
        const items = block.items.filter((item) => item.trim());
        if (items.length === 0) break;
        const tag = block.ordered ? 'ol' : 'ul';
        parts.push(
          `<${tag}>${items.map((item) => `<li>${escapeHtml(item.trim())}</li>`).join('')}</${tag}>`,
        );
        break;
      }
      case 'image': {
        const enriched = block as ResolvedNewsBodyBlock & { type: 'image' };
        if (enriched.url) {
          const alt = escapeHtml(enriched.altText ?? enriched.caption ?? '');
          parts.push(`<figure><img src="${escapeHtml(enriched.url)}" alt="${alt}" />`);
          if (enriched.caption) {
            parts.push(`<figcaption>${escapeHtml(enriched.caption)}</figcaption>`);
          }
          parts.push('</figure>');
        }
        break;
      }
      case 'video': {
        const enriched = block as ResolvedNewsBodyBlock & { type: 'video' };
        if (enriched.url) {
          parts.push(`<video controls src="${escapeHtml(enriched.url)}"></video>`);
          if (enriched.caption) {
            parts.push(`<p>${escapeHtml(enriched.caption)}</p>`);
          }
        }
        break;
      }
      case 'gallery': {
        const items = (block as EnrichedGalleryBlock).items as EnrichedGalleryItem[];
        const figures = items
          .filter((item) => Boolean(item.url))
          .map((item) => {
            const alt = escapeHtml(item.altText ?? item.caption ?? '');
            let fig = `<figure><img src="${escapeHtml(item.url!)}" alt="${alt}" />`;
            if (item.caption) {
              fig += `<figcaption>${escapeHtml(item.caption)}</figcaption>`;
            }
            fig += '</figure>';
            return fig;
          });
        if (figures.length > 0) {
          parts.push(`<div class="news-gallery">${figures.join('')}</div>`);
        }
        break;
      }
      case 'quote': {
        const text = block.text.trim();
        if (text) {
          let html = `<blockquote><p>${escapeHtml(text)}</p>`;
          if (block.attribution?.trim()) {
            html += `<cite>${escapeHtml(block.attribution.trim())}</cite>`;
          }
          html += '</blockquote>';
          parts.push(html);
        }
        break;
      }
      case 'divider':
        parts.push('<hr />');
        break;
      case 'embed': {
        if (block.url.trim()) {
          parts.push(buildEmbedIframeHtml(block.url.trim()));
        }
        break;
      }
      default:
        break;
    }
  }

  return parts.join('\n');
}
