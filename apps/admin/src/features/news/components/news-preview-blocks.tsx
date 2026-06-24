'use client';

import Image from 'next/image';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import styles from './news-preview-blocks.module.css';

export type ResolvedPreviewBlock =
  | { type: 'paragraph'; text: string }
  | { type: 'image'; url: string | null; caption?: string; altText?: string }
  | { type: 'video'; url: string | null; caption?: string };

export function resolvePreviewBlocks(
  blocks: NewsBodyBlock[],
  media: NewsMediaDto[],
  locale: string,
): ResolvedPreviewBlock[] {
  const byId = new Map(media.map((m) => [m.id, m]));
  return blocks.map((block) => {
    if (block.type === 'paragraph') {
      return { type: 'paragraph', text: block.text };
    }
    const item = byId.get(block.mediaId);
    const url = item?.url ?? null;
    const altText = item?.altText?.[locale as keyof NonNullable<NewsMediaDto['altText']>] ?? undefined;
    if (block.type === 'image') {
      return {
        type: 'image' as const,
        url,
        ...(block.caption ? { caption: block.caption } : {}),
        ...(altText ? { altText } : {}),
      };
    }
    return {
      type: 'video' as const,
      url,
      ...(block.caption ? { caption: block.caption } : {}),
    };
  });
}

type NewsPreviewBlocksProps = {
  body: ResolvedPreviewBlock[];
};

/** Mirrors landing NewsArticleBlocks markup for admin live preview. */
export function NewsPreviewBlocks({ body }: NewsPreviewBlocksProps) {
  return (
    <>
      {body.map((block, i) => {
        if (block.type === 'paragraph') {
          return (
            <p key={i} className={styles.paragraph}>
              {block.text}
            </p>
          );
        }
        if (block.type === 'image') {
          if (!block.url) {
            return (
              <figure key={i} className={styles.figure}>
                <div className={styles.mediaPlaceholder}>Image unavailable</div>
              </figure>
            );
          }
          return (
            <figure key={i} className={styles.figure}>
              <div className={styles.imageWrap}>
                <Image
                  src={block.url}
                  alt={block.caption ?? block.altText ?? ''}
                  fill
                  className={styles.image}
                  sizes="(min-width: 768px) 768px, 100vw"
                  unoptimized
                />
              </div>
              {block.caption ? <figcaption className={styles.caption}>{block.caption}</figcaption> : null}
            </figure>
          );
        }
        if (block.type === 'video') {
          if (!block.url) {
            return (
              <figure key={i} className={styles.figure}>
                <div className={styles.videoPlaceholder}>Video unavailable</div>
              </figure>
            );
          }
          return (
            <figure key={i} className={styles.figure}>
              <video className={styles.video} controls preload="metadata" src={block.url} />
              {block.caption ? <figcaption className={styles.caption}>{block.caption}</figcaption> : null}
            </figure>
          );
        }
        return null;
      })}
    </>
  );
}
