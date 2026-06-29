'use client';

import Image from 'next/image';
import { useTranslations } from 'next-intl';
import { Button, EmptyState, Input } from '@/components/ui';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import type { NewsFormLocale } from '../types';
import { NEWS_LOCALES } from '../types';
import { insertBlockAt } from '../lib/news-block-factory';
import { useOptionalNewsDocumentEditor } from '../context/news-document-editor-context';
import styles from './news-media-library.module.css';

type NewsMediaLibraryProps = {
  media: NewsMediaDto[];
  bodyBlockCount: number;
  readOnly: boolean;
  busy: boolean;
  embedded?: boolean;
  onInsertAt: (mediaId: string, kind: 'inline_image' | 'inline_video', insertIndex: number) => void;
  onDelete: (mediaId: string) => void;
  onAltTextChange?: (mediaId: string, locale: NewsFormLocale, value: string) => void;
};

export function NewsMediaLibrary({
  media,
  bodyBlockCount,
  readOnly,
  busy,
  embedded = false,
  onInsertAt,
  onDelete,
  onAltTextChange,
}: NewsMediaLibraryProps) {
  const t = useTranslations('news');
  const documentEditor = useOptionalNewsDocumentEditor();
  const insertIndex = documentEditor ? documentEditor.resolveInsertIndex(bodyBlockCount) : bodyBlockCount;

  if (readOnly && media.length === 0) return null;

  return (
    <section className={embedded ? styles.embedded : styles.root} aria-label={t('form.mediaLibrary')}>
      {!embedded ? <h3 className={styles.title}>{t('form.mediaLibrary')}</h3> : null}
      {!readOnly ? <p className={styles.libraryHint}>{t('mediaGuidance.library')}</p> : null}
      {media.length === 0 ? (
        readOnly ? (
          <p className={styles.empty}>{t('form.noMedia')}</p>
        ) : (
          <EmptyState
            title={t('form.noMedia')}
            description={t('form.noMediaHint')}
            icon="document-text"
          />
        )
      ) : (
        <ul className={styles.grid}>
          {media.map((m) => (
            <li key={m.id} className={styles.item}>
              {m.url && m.kind !== 'inline_video' ? (
                <div className={styles.thumb}>
                  <Image src={m.url} alt="" fill className={styles.thumbImage} unoptimized />
                </div>
              ) : m.url && m.kind === 'inline_video' ? (
                <video src={m.url} className={styles.videoThumb} />
              ) : (
                <div className={styles.thumbPlaceholder}>{m.kind}</div>
              )}
              <div className={styles.meta}>
                <span className={styles.fileName}>{m.fileName ?? m.id.slice(0, 8)}</span>
                <span className={styles.kind}>{m.kind}</span>
              </div>
              {!readOnly && onAltTextChange && m.kind !== 'inline_video' ? (
                <div className={styles.altFields}>
                  {NEWS_LOCALES.map((loc) => (
                    <Input
                      key={loc}
                      label={t('form.altText', { locale: loc.toUpperCase() })}
                      value={m.altText?.[loc] ?? ''}
                      onChange={(e) => onAltTextChange(m.id, loc, e.target.value)}
                      disabled={busy}
                    />
                  ))}
                </div>
              ) : readOnly && m.altText ? (
                <div className={styles.altFields}>
                  {NEWS_LOCALES.filter((loc) => m.altText?.[loc]).map((loc) => (
                    <p key={loc} className={styles.altReadOnly}>
                      <span className={styles.altLabel}>{loc.toUpperCase()}:</span> {m.altText?.[loc]}
                    </p>
                  ))}
                </div>
              ) : null}
              {!readOnly ? (
                <div className={styles.actions}>
                  {m.kind === 'inline_image' || m.kind === 'inline_video' ? (
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      disabled={busy}
                      onClick={() =>
                        onInsertAt(
                          m.id,
                          m.kind === 'inline_video' ? 'inline_video' : 'inline_image',
                          insertIndex,
                        )
                      }
                    >
                      {t('form.insertMedia')}
                    </Button>
                  ) : null}
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    disabled={busy}
                    onClick={() => onDelete(m.id)}
                  >
                    {t('form.deleteMedia')}
                  </Button>
                </div>
              ) : null}
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

export function insertMediaBlockAt(
  blocks: NewsBodyBlock[],
  mediaId: string,
  kind: 'inline_image' | 'inline_video',
  insertIndex: number,
): NewsBodyBlock[] {
  const block: NewsBodyBlock =
    kind === 'inline_video' ? { type: 'video', mediaId } : { type: 'image', mediaId };
  return insertBlockAt(blocks, insertIndex, block);
}

/** @deprecated Use insertMediaBlockAt */
export function insertMediaBlock(
  blocks: NewsBodyBlock[],
  mediaId: string,
  kind: 'inline_image' | 'inline_video',
): NewsBodyBlock[] {
  return insertMediaBlockAt(blocks, mediaId, kind, blocks.length);
}
