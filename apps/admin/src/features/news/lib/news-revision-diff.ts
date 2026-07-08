import type { NewsBodyBlock } from '@chisto/news-content';
import type { NewsPostAdminDto } from '../news-api-types';
import type { NewsFormLocale } from '../types';
import { NEWS_LOCALES } from '../types';

export type RevisionDiffSummary = {
  titleChanged: boolean;
  excerptChanged: boolean;
  blockDelta: number;
  mediaDelta: number;
};

export function summarizeLocaleContentDiff(
  before: { title: string; excerpt: string; body: NewsBodyBlock[] },
  after: { title: string; excerpt: string; body: NewsBodyBlock[] },
): RevisionDiffSummary {
  const beforeMedia = new Set(
    before.body.flatMap((block) => {
      if (block.type === 'image' || block.type === 'video') return block.mediaId ? [block.mediaId] : [];
      if (block.type === 'gallery') return block.items.map((item) => item.mediaId).filter(Boolean);
      return [];
    }),
  );
  const afterMedia = new Set(
    after.body.flatMap((block) => {
      if (block.type === 'image' || block.type === 'video') return block.mediaId ? [block.mediaId] : [];
      if (block.type === 'gallery') return block.items.map((item) => item.mediaId).filter(Boolean);
      return [];
    }),
  );

  let mediaDelta = 0;
  for (const id of afterMedia) if (!beforeMedia.has(id)) mediaDelta += 1;
  for (const id of beforeMedia) if (!afterMedia.has(id)) mediaDelta -= 1;

  return {
    titleChanged: before.title.trim() !== after.title.trim(),
    excerptChanged: before.excerpt.trim() !== after.excerpt.trim(),
    blockDelta: after.body.length - before.body.length,
    mediaDelta,
  };
}

export function summarizeRevisionDiff(
  current: NewsPostAdminDto,
  snapshot: NewsPostAdminDto['translations'],
  locale: NewsFormLocale = 'en',
): RevisionDiffSummary {
  const before = snapshot[locale];
  const after = current.translations[locale];
  const beforeMedia = new Set(
    before.body.flatMap((block) => {
      if (block.type === 'image' || block.type === 'video') return block.mediaId ? [block.mediaId] : [];
      if (block.type === 'gallery') {
        return block.items.map((item) => item.mediaId).filter(Boolean);
      }
      return [];
    }),
  );
  const afterMedia = new Set(
    after.body.flatMap((block) => {
      if (block.type === 'image' || block.type === 'video') return block.mediaId ? [block.mediaId] : [];
      if (block.type === 'gallery') {
        return block.items.map((item) => item.mediaId).filter(Boolean);
      }
      return [];
    }),
  );

  let mediaDelta = 0;
  for (const id of afterMedia) if (!beforeMedia.has(id)) mediaDelta += 1;
  for (const id of beforeMedia) if (!afterMedia.has(id)) mediaDelta -= 1;

  return {
    titleChanged: before.title.trim() !== after.title.trim(),
    excerptChanged: before.excerpt.trim() !== after.excerpt.trim(),
    blockDelta: after.body.length - before.body.length,
    mediaDelta,
  };
}

export function revisionDiffTouchesLocales(
  current: NewsPostAdminDto,
  snapshot: NewsPostAdminDto['translations'],
): NewsFormLocale[] {
  return NEWS_LOCALES.filter((locale) => {
    const summary = summarizeRevisionDiff(current, snapshot, locale);
    return summary.titleChanged || summary.excerptChanged || summary.blockDelta !== 0 || summary.mediaDelta !== 0;
  });
}
