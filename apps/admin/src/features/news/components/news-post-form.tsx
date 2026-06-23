'use client';

import { useTranslations } from 'next-intl';
import { Button, Input, Select } from '@/components/ui';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import type { NewsFormLocale, NewsPostFormValues } from '../types';
import { NEWS_CATEGORIES, NEWS_LOCALES } from '../types';
import styles from './news-post-form.module.css';

type NewsPostFormProps = {
  values: NewsPostFormValues;
  locale: NewsFormLocale;
  media: NewsMediaDto[];
  status: string;
  busy: boolean;
  onLocaleChange: (locale: NewsFormLocale) => void;
  onChange: <K extends keyof NewsPostFormValues>(key: K, value: NewsPostFormValues[K]) => void;
  onBodyChange: (blocks: NewsBodyBlock[]) => void;
  onUploadCover: (file: File) => void;
  onUploadInline: (file: File, kind: 'inline_image' | 'inline_video') => void;
};

export function NewsPostForm({
  values,
  locale,
  media,
  status,
  busy,
  onLocaleChange,
  onChange,
  onBodyChange,
  onUploadCover,
  onUploadInline,
}: NewsPostFormProps) {
  const t = useTranslations('news');
  const content = values.translations[locale];

  function updateBlock(index: number, block: NewsBodyBlock) {
    const next = [...content.body];
    next[index] = block;
    onBodyChange(next);
  }

  function addParagraph() {
    onBodyChange([...content.body, { type: 'paragraph', text: '' }]);
  }

  function removeBlock(index: number) {
    onBodyChange(content.body.filter((_, i) => i !== index));
  }

  const inlineMedia = media.filter((m) => m.kind !== 'cover');

  return (
    <div className={styles.root}>
      <div className={styles.localeTabs}>
        {NEWS_LOCALES.map((loc) => (
          <button
            key={loc}
            type="button"
            className={loc === locale ? styles.localeActive : styles.localeTab}
            onClick={() => onLocaleChange(loc)}
          >
            {loc.toUpperCase()}
          </button>
        ))}
      </div>

      <Input
        label={t('form.slug')}
        value={values.slug}
        onChange={(e) => onChange('slug', e.target.value)}
        disabled={busy || status === 'published'}
      />
      <Select
        label={t('form.category')}
        value={values.category}
        options={NEWS_CATEGORIES.map((c) => ({ value: c, label: t(`category.${c}`) }))}
        onChange={(e) => onChange('category', e.target.value as NewsPostFormValues['category'])}
        disabled={busy}
      />
      <Input
        label={t('form.scheduledAt')}
        type="datetime-local"
        value={values.scheduledAt}
        onChange={(e) => onChange('scheduledAt', e.target.value)}
        disabled={busy}
      />

      <Input
        label={t('form.title')}
        value={content.title}
        onChange={(e) =>
          onChange('translations', {
            ...values.translations,
            [locale]: { ...content, title: e.target.value },
          })
        }
        disabled={busy}
      />
      <label className={styles.field}>
        <span className={styles.label}>{t('form.excerpt')}</span>
        <textarea
          className={styles.textarea}
          rows={3}
          value={content.excerpt}
          onChange={(e) =>
            onChange('translations', {
              ...values.translations,
              [locale]: { ...content, excerpt: e.target.value },
            })
          }
          disabled={busy}
        />
      </label>

      <div className={styles.coverSection}>
        <span className={styles.label}>{t('form.cover')}</span>
        <input
          type="file"
          accept="image/*,video/mp4,video/webm"
          disabled={busy}
          onChange={(e) => {
            const file = e.target.files?.[0];
            if (file) onUploadCover(file);
            e.target.value = '';
          }}
        />
      </div>

      <div className={styles.bodySection}>
        <div className={styles.bodyHeader}>
          <span className={styles.label}>{t('form.body')}</span>
          <Button type="button" variant="outline" size="sm" onClick={addParagraph} disabled={busy}>
            {t('form.addParagraph')}
          </Button>
        </div>
        {content.body.map((block, index) => (
          <div key={`${locale}-${index}`} className={styles.block}>
            {block.type === 'paragraph' ? (
              <textarea
                className={styles.textarea}
                rows={4}
                value={block.text}
                onChange={(e) => updateBlock(index, { type: 'paragraph', text: e.target.value })}
                disabled={busy}
              />
            ) : (
              <p className={styles.mediaRef}>
                {block.type}: {block.mediaId}
                {block.caption ? ` — ${block.caption}` : ''}
              </p>
            )}
            <Button type="button" variant="ghost" size="sm" onClick={() => removeBlock(index)} disabled={busy}>
              {t('form.removeBlock')}
            </Button>
          </div>
        ))}
        <div className={styles.inlineUpload}>
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
        {inlineMedia.length > 0 ? (
          <ul className={styles.mediaList}>
            {inlineMedia.map((m) => (
              <li key={m.id}>
                {m.fileName ?? m.id} ({m.kind})
              </li>
            ))}
          </ul>
        ) : null}
      </div>
    </div>
  );
}
