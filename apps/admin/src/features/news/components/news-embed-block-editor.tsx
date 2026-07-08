'use client';

import {
  embedProviderFromUrl,
  embedUrlFromVideoLink,
} from '@chisto/news-content';
import { RenderNewsBlocks } from '@chisto/news-content/render';
import { useTranslations } from 'next-intl';
import { useMemo, useState } from 'react';
import { Input } from '@/components/ui';
import type { NewsBodyBlock } from '../news-api-types';
import styles from './news-embed-block-editor.module.css';

type EmbedBlock = Extract<NewsBodyBlock, { type: 'embed' }>;

type NewsEmbedBlockEditorProps = {
  block: EmbedBlock;
  readOnly: boolean;
  autoFocus?: boolean | undefined;
  onChange: (block: EmbedBlock) => void;
};

export function NewsEmbedBlockEditor({
  block,
  readOnly,
  autoFocus = false,
  onChange,
}: NewsEmbedBlockEditorProps) {
  const t = useTranslations('news');
  const tPreview = useTranslations('news.previewBlocks');
  const [draftUrl, setDraftUrl] = useState('');
  const [error, setError] = useState<string | null>(null);

  const previewBlock = useMemo((): NewsBodyBlock[] | null => {
    const url = block.url?.trim();
    if (!url) return null;
    return [{ type: 'embed', provider: block.provider, url }];
  }, [block.provider, block.url]);

  function applyUrl(raw: string) {
    const trimmed = raw.trim();
    if (!trimmed) {
      setError(t('form.embedUrlRequired'));
      return;
    }
    const embed = embedUrlFromVideoLink(trimmed) ?? (embedProviderFromUrl(trimmed) ? trimmed : null);
    if (!embed) {
      setError(t('form.embedUrlInvalid'));
      return;
    }
    const provider = embedProviderFromUrl(embed);
    if (!provider) {
      setError(t('form.embedUrlInvalid'));
      return;
    }
    onChange({ ...block, url: embed, provider });
    setDraftUrl('');
    setError(null);
  }

  return (
    <div className={styles.root}>
      {!readOnly ? (
        <div className={styles.urlRow}>
          <Input
            value={draftUrl}
            onChange={(e) => {
              setDraftUrl(e.target.value);
              setError(null);
            }}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault();
                applyUrl(draftUrl);
              }
            }}
            placeholder={t('form.embedUrlPlaceholder')}
            aria-label={t('form.embedUrl')}
            disabled={readOnly}
            {...(autoFocus ? { autoFocus: true } : {})}
          />
          <button type="button" className={styles.applyBtn} onClick={() => applyUrl(draftUrl)}>
            {t('form.embedApply')}
          </button>
        </div>
      ) : null}
      {error ? <p className={styles.error}>{error}</p> : null}
      {previewBlock ? (
        <RenderNewsBlocks
          blocks={previewBlock}
          labels={{
            imageUnavailable: tPreview('imageUnavailable'),
            videoUnavailable: tPreview('videoUnavailable'),
          }}
          className={styles.preview}
        />
      ) : (
        <p className={styles.empty}>{t('form.embedEmptyHint')}</p>
      )}
      {block.url?.trim() && !readOnly ? (
        <button
          type="button"
          className={styles.clearBtn}
          onClick={() => onChange({ ...block, url: '', provider: 'youtube' })}
        >
          {t('form.embedClear')}
        </button>
      ) : null}
    </div>
  );
}
