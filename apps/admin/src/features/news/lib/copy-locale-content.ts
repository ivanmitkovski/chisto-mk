import { createBlockId, type NewsBodyBlock } from '@chisto/news-content';
import type { NewsFormLocale, NewsPostFormValues } from '../types';

export function copyBodyBlocksFromSource(blocks: NewsBodyBlock[]): NewsBodyBlock[] {
  return blocks.map((block) => {
    const id = createBlockId();
    if (block.type === 'paragraph') {
      return {
        id,
        type: 'paragraph',
        text: block.text,
        ...(block.html ? { html: block.html } : {}),
      };
    }
    if (block.type === 'html') {
      return { id, type: 'html', html: block.html };
    }
    if (block.type === 'heading') {
      return { id, type: 'heading', level: block.level, text: block.text };
    }
    if (block.type === 'list') {
      return { id, type: 'list', ordered: block.ordered, items: [...block.items] };
    }
    if (block.type === 'image') {
      return {
        id,
        type: 'image',
        mediaId: block.mediaId,
        ...(block.caption ? { caption: block.caption } : {}),
      };
    }
    if (block.type === 'gallery') {
      return {
        id,
        type: 'gallery',
        items: block.items.map((item) => ({
          mediaId: item.mediaId,
          ...(item.caption ? { caption: item.caption } : {}),
        })),
      };
    }
    if (block.type === 'video') {
      return {
        id,
        type: 'video',
        mediaId: block.mediaId,
        ...(block.caption ? { caption: block.caption } : {}),
      };
    }
    return block;
  });
}

export function copyLocaleFromSource(
  values: NewsPostFormValues,
  source: NewsFormLocale,
  target: NewsFormLocale,
): NewsPostFormValues['translations'] {
  const src = values.translations[source];
  const targetEntry = values.translations[target];
  return {
    ...values.translations,
    [target]: {
      ...targetEntry,
      title: src.title,
      excerpt: src.excerpt,
      body: copyBodyBlocksFromSource(src.body),
    },
  };
}
