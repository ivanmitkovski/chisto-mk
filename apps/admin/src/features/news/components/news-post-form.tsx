'use client';

import { useTranslations } from 'next-intl';
import { Button, Input, Select } from '@/components/ui';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import type { NewsFormLocale, NewsPostFormValues } from '../types';
import { NEWS_CATEGORIES, NEWS_LOCALES } from '../types';
import { localeCompleteness } from '../lib/news-locale-utils';
import { NewsBodyBlockEditor } from './news-body-block-editor';
import { NewsLocaleCompleteness } from './news-locale-completeness';
import styles from './news-post-form.module.css';

type NewsPostFormProps = {
  values: NewsPostFormValues;
  locale: NewsFormLocale;
  media: NewsMediaDto[];
  status: string;
  busy: boolean;
  readOnly: boolean;
  hasCover: boolean;
  onLocaleChange: (locale: NewsFormLocale) => void;
  onChange: <K extends keyof NewsPostFormValues>(key: K, value: NewsPostFormValues[K]) => void;
  onBodyChange: (blocks: NewsBodyBlock[]) => void;
  onCopyFromLocale?: (source: NewsFormLocale) => void;
};

export function NewsPostForm({
  values,
  locale,
  media,
  status,
  busy,
  readOnly,
  hasCover,
  onLocaleChange,
  onChange,
  onBodyChange,
  onCopyFromLocale,
}: NewsPostFormProps) {
  const t = useTranslations('news');
  const content = values.translations[locale];
  const scores = localeCompleteness(values, hasCover);

  function moveBlock(index: number, direction: -1 | 1) {
    const next = [...content.body];
    const target = index + direction;
    if (target < 0 || target >= next.length) return;
    [next[index], next[target]] = [next[target], next[index]];
    onBodyChange(next);
  }

  function updateBlock(index: number, block: NewsBodyBlock) {
    const next = [...content.body];
    next[index] = block;
    onBodyChange(next);
  }

  return (
    <div className={styles.root}>
      <NewsLocaleCompleteness values={values} hasCover={hasCover} activeLocale={locale} />

      <div className={styles.localeTabs} role="tablist" aria-label={t('form.locales')}>
        {NEWS_LOCALES.map((loc) => (
          <button
            key={loc}
            type="button"
            role="tab"
            aria-selected={loc === locale}
            className={loc === locale ? styles.localeActive : styles.localeTab}
            onClick={() => onLocaleChange(loc)}
          >
            {loc.toUpperCase()}
            <span className={scores[loc] ? styles.dotComplete : styles.dotIncomplete} aria-hidden />
          </button>
        ))}
      </div>

      {!readOnly && locale !== 'en' && onCopyFromLocale ? (
        <Button type="button" variant="outline" size="sm" disabled={busy} onClick={() => onCopyFromLocale('en')}>
          {t('form.copyFromEn')}
        </Button>
      ) : null}

      <Input
        label={t('form.slug')}
        value={values.slug}
        onChange={(e) => onChange('slug', e.target.value)}
        disabled={busy || readOnly || status === 'published'}
      />
      {values.slug.trim() ? (
        <p className={styles.slugPreview}>{t('form.slugPreview', { slug: values.slug.trim() })}</p>
      ) : null}
      <Select
        label={t('form.category')}
        value={values.category}
        options={NEWS_CATEGORIES.map((c) => ({ value: c, label: t(`category.${c}`) }))}
        onChange={(e) => onChange('category', e.target.value as NewsPostFormValues['category'])}
        disabled={busy || readOnly}
      />
      <Input
        label={t('form.scheduledAt')}
        type="datetime-local"
        value={values.scheduledAt}
        onChange={(e) => onChange('scheduledAt', e.target.value)}
        disabled={busy || readOnly}
      />
      <label className={styles.checkboxField}>
        <input
          type="checkbox"
          checked={values.featured}
          onChange={(e) => onChange('featured', e.target.checked)}
          disabled={busy || readOnly}
        />
        <span>{t('form.featured')}</span>
      </label>

      <Input
        label={t('form.title')}
        value={content.title}
        onChange={(e) =>
          onChange('translations', {
            ...values.translations,
            [locale]: { ...content, title: e.target.value },
          })
        }
        disabled={busy || readOnly}
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
          disabled={busy || readOnly}
          maxLength={500}
        />
      </label>

      <div className={styles.bodySection} role="tabpanel">
        <div className={styles.bodyHeader}>
          <span className={styles.label}>{t('form.body')}</span>
          {!readOnly ? (
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => onBodyChange([...content.body, { type: 'paragraph', text: '' }])}
              disabled={busy}
            >
              {t('form.addParagraph')}
            </Button>
          ) : null}
        </div>
        {content.body.map((block, index) => (
          <NewsBodyBlockEditor
            key={`${locale}-${index}-${block.type}`}
            block={block}
            index={index}
            total={content.body.length}
            media={media}
            readOnly={readOnly}
            busy={busy}
            onChange={(next) => updateBlock(index, next)}
            onRemove={() => onBodyChange(content.body.filter((_, i) => i !== index))}
            onMoveUp={() => moveBlock(index, -1)}
            onMoveDown={() => moveBlock(index, 1)}
          />
        ))}
      </div>
    </div>
  );
}
