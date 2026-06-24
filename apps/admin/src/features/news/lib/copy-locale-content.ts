import type { NewsBodyBlock } from '../news-api-types';
import type { NewsFormLocale, NewsPostFormValues } from '../types';

export function copyBodyBlocksFromSource(blocks: NewsBodyBlock[]): NewsBodyBlock[] {
  return blocks.map((block) => {
    if (block.type === 'paragraph') {
      return { type: 'paragraph', text: block.text };
    }
    if (block.type === 'image') {
      return {
        type: 'image',
        mediaId: block.mediaId,
        ...(block.caption ? { caption: block.caption } : {}),
      };
    }
    return {
      type: 'video',
      mediaId: block.mediaId,
      ...(block.caption ? { caption: block.caption } : {}),
    };
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
