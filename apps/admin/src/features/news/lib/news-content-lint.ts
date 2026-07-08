import {
  galleryHasContent,
  hasVisibleText,
  htmlBlockHasContent,
  wordCountFromBlocks,
  type NewsBodyBlock,
} from '@chisto/news-content';
import type { NewsMediaDto } from '../news-api-types';
import type { NewsFormLocale, NewsPostFormValues } from '../types';
import { NEWS_LOCALES } from '../types';
import { MAX_BODY_BLOCKS, MAX_EXCERPT_LENGTH, MAX_TITLE_LENGTH } from './news-post-policy';
import { bodyBlocksValidForPublish, inlineImageAltCompleteForLocale } from './news-locale-utils';

export type NewsLintSeverity = 'error' | 'warning';

export type NewsLintIssueId =
  | 'titleMissing'
  | 'titleTooLong'
  | 'excerptMissing'
  | 'excerptTooLong'
  | 'bodyEmpty'
  | 'bodyInvalid'
  | 'bodyLimit'
  | 'coverMissing'
  | 'altTextMissing'
  | 'mediaMissing'
  | 'embedEmpty'
  | 'quoteEmpty'
  | 'localeIncomplete';

export type NewsLintIssue = {
  id: NewsLintIssueId;
  severity: NewsLintSeverity;
  locale: NewsFormLocale;
  messageKey: `lint.${NewsLintIssueId}`;
  jump?: 'title' | 'excerpt' | 'body' | 'cover' | 'media' | 'locale';
};

export type NewsReadingStats = {
  wordCount: number;
  readingMinutes: number;
};

const WORDS_PER_MINUTE = 200;

export function readingStatsFromBlocks(blocks: NewsBodyBlock[]): NewsReadingStats {
  const wordCount = wordCountFromBlocks(blocks);
  return {
    wordCount,
    readingMinutes: Math.max(1, Math.ceil(wordCount / WORDS_PER_MINUTE)),
  };
}

function mediaIdsSet(media: NewsMediaDto[]): Set<string> {
  return new Set(media.map((item) => item.id));
}

export function lintNewsContent(
  values: NewsPostFormValues,
  hasCover: boolean,
  media: NewsMediaDto[],
): NewsLintIssue[] {
  const issues: NewsLintIssue[] = [];
  const knownMedia = mediaIdsSet(media);

  for (const locale of NEWS_LOCALES) {
    const entry = values.translations[locale];
    const title = entry.title.trim();
    const excerpt = entry.excerpt.trim();
    const bodyPublishInvalid = entry.body.length > 0 && !bodyBlocksValidForPublish(entry.body);

    if (!title) {
      issues.push({
        id: 'titleMissing',
        severity: 'error',
        locale,
        messageKey: 'lint.titleMissing',
        jump: 'title',
      });
    } else if (title.length > MAX_TITLE_LENGTH) {
      issues.push({
        id: 'titleTooLong',
        severity: 'error',
        locale,
        messageKey: 'lint.titleTooLong',
        jump: 'title',
      });
    }

    if (!excerpt) {
      issues.push({
        id: 'excerptMissing',
        severity: 'error',
        locale,
        messageKey: 'lint.excerptMissing',
        jump: 'excerpt',
      });
    } else if (excerpt.length > MAX_EXCERPT_LENGTH) {
      issues.push({
        id: 'excerptTooLong',
        severity: 'error',
        locale,
        messageKey: 'lint.excerptTooLong',
        jump: 'excerpt',
      });
    }

    if (entry.body.length === 0) {
      issues.push({
        id: 'bodyEmpty',
        severity: 'error',
        locale,
        messageKey: 'lint.bodyEmpty',
        jump: 'body',
      });
    } else if (!bodyBlocksValidForPublish(entry.body)) {
      issues.push({
        id: 'bodyInvalid',
        severity: 'error',
        locale,
        messageKey: 'lint.bodyInvalid',
        jump: 'body',
      });
    }

    if (entry.body.length > MAX_BODY_BLOCKS) {
      issues.push({
        id: 'bodyLimit',
        severity: 'error',
        locale,
        messageKey: 'lint.bodyLimit',
        jump: 'body',
      });
    }

    for (const block of entry.body) {
      if (block.type === 'quote' && !block.text.trim()) {
        issues.push({
          id: 'quoteEmpty',
          severity: 'warning',
          locale,
          messageKey: 'lint.quoteEmpty',
          jump: 'body',
        });
      }
      if (block.type === 'embed' && !block.url?.trim()) {
        issues.push({
          id: 'embedEmpty',
          severity: 'warning',
          locale,
          messageKey: 'lint.embedEmpty',
          jump: 'body',
        });
      }
      if (block.type === 'image' || block.type === 'video') {
        if (block.mediaId.trim() && !knownMedia.has(block.mediaId)) {
          issues.push({
            id: 'mediaMissing',
            severity: 'error',
            locale,
            messageKey: 'lint.mediaMissing',
            jump: 'body',
          });
        }
      }
      if (block.type === 'gallery' && galleryHasContent(block)) {
        for (const item of block.items) {
          if (item.mediaId?.trim() && !knownMedia.has(item.mediaId)) {
            issues.push({
              id: 'mediaMissing',
              severity: 'error',
              locale,
              messageKey: 'lint.mediaMissing',
              jump: 'body',
            });
          }
        }
      }
      if (block.type === 'paragraph') {
        const html = block.html?.trim();
        if (
          !bodyPublishInvalid &&
          !block.text.trim() &&
          html &&
          !hasVisibleText(html)
        ) {
          issues.push({
            id: 'bodyInvalid',
            severity: 'warning',
            locale,
            messageKey: 'lint.bodyInvalid',
            jump: 'body',
          });
        }
      }
      if (
        !bodyPublishInvalid &&
        block.type === 'html' &&
        block.html.trim() &&
        !htmlBlockHasContent(block.html)
      ) {
        issues.push({
          id: 'bodyInvalid',
          severity: 'warning',
          locale,
          messageKey: 'lint.bodyInvalid',
          jump: 'body',
        });
      }
    }

    if (!inlineImageAltCompleteForLocale(entry.body, media, locale)) {
      issues.push({
        id: 'altTextMissing',
        severity: 'error',
        locale,
        messageKey: 'lint.altTextMissing',
        jump: 'media',
      });
    }
  }

  if (!hasCover) {
    issues.push({
      id: 'coverMissing',
      severity: 'error',
      locale: 'en',
      messageKey: 'lint.coverMissing',
      jump: 'cover',
    });
  }

  return issues;
}
