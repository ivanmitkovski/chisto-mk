'use client';

import Image from 'next/image';
import { useTranslations } from 'next-intl';
import { Button, Input } from '@/components/ui';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import type { NewsFormLocale } from '../types';
import { NEWS_LOCALES } from '../types';
import styles from './news-media-library.module.css';

type NewsMediaLibraryProps = {
  media: NewsMediaDto[];
  readOnly: boolean;
  busy: boolean;
  onInsert: (mediaId: string, kind: 'inline_image' | 'inline_video') => void;
  onDelete: (mediaId: string) => void;
  onUploadCover: (file: File) => void;
  onUploadInline: (file: File, kind: 'inline_image' | 'inline_video') => void;
  onAltTextChange?: (mediaId: string, locale: NewsFormLocale, value: string) => void;
};

export function NewsMediaLibrary({
  media,
  readOnly,
  busy,
  onInsert,
  onDelete,
  onUploadCover,
  onUploadInline,
  onAltTextChange,
}: NewsMediaLibraryProps) {
  const t = useTranslations('news');

  if (readOnly && media.length === 0) return null;

  return (
    <section className={styles.root} aria-label={t('form.mediaLibrary')}>
      <h3 className={styles.title}>{t('form.mediaLibrary')}</h3>
      {!readOnly ? (
        <div className={styles.uploadRow}>
          <label className={styles.uploadBtn}>
            {t('form.uploadCover')}
            <input
              type="file"
              accept="image/*,video/mp4,video/webm"
              disabled={busy}
              hidden
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) onUploadCover(file);
                e.target.value = '';
              }}
            />
          </label>
          <Button
            type="button"
            variant="outline"
            size="sm"
            disabled={busy}
            onClick={() => {
              const input = document.createElement('input');
              input.type = 'file';
              input.accept = 'image/*';
              input.onchange = () => {
                const file = input.files?.[0];
                if (file) onUploadInline(file, 'inline_image');
              };
              input.click();
            }}
          >
            {t('form.addImage')}
          </Button>
          <Button
            type="button"
            variant="outline"
            size="sm"
            disabled={busy}
            onClick={() => {
              const input = document.createElement('input');
              input.type = 'file';
              input.accept = 'video/mp4,video/webm,video/quicktime';
              input.onchange = () => {
                const file = input.files?.[0];
                if (file) onUploadInline(file, 'inline_video');
              };
              input.click();
            }}
          >
            {t('form.addVideo')}
          </Button>
        </div>
      ) : null}
      {media.length === 0 ? (
        <p className={styles.empty}>{t('form.noMedia')}</p>
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
                        onInsert(
                          m.id,
                          m.kind === 'inline_video' ? 'inline_video' : 'inline_image',
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

export function insertMediaBlock(
  blocks: NewsBodyBlock[],
  mediaId: string,
  kind: 'inline_image' | 'inline_video',
): NewsBodyBlock[] {
  const block: NewsBodyBlock =
    kind === 'inline_video' ? { type: 'video', mediaId } : { type: 'image', mediaId };
  return [...blocks, block];
}
