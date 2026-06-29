'use client';

import { useMemo, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Checkbox, ConfirmDialog, DateTimePicker, Input, Select, Tabs } from '@/components/ui';
import type { NewsMediaDto } from '../news-api-types';
import {
  applyContentTemplate,
  NEWS_CONTENT_TEMPLATE_OPTIONS,
  type NewsContentTemplateId,
} from '../lib/news-content-templates';
import type { NewsFormLocale, NewsPostFormValues } from '../types';
import { NEWS_CATEGORIES, NEWS_LOCALES } from '../types';
import { NewsLocaleCompleteness } from './news-locale-completeness';
import styles from './news-post-form.module.css';

type NewsPostFormProps = {
  values: NewsPostFormValues;
  locale: NewsFormLocale;
  media: NewsMediaDto[];
  status: string;
  busy: boolean;
  saving?: boolean;
  readOnly: boolean;
  hasCover: boolean;
  onLocaleChange: (locale: NewsFormLocale) => void;
  onChange: <K extends keyof NewsPostFormValues>(key: K, value: NewsPostFormValues[K]) => void;
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
  onCopyFromLocale,
}: NewsPostFormProps) {
  const t = useTranslations('news');
  const [pendingTemplate, setPendingTemplate] = useState<{ id: NewsContentTemplateId; loc: NewsFormLocale } | null>(null);

  const localeTabs = useMemo(
    () =>
      NEWS_LOCALES.map((loc) => {
        const content = values.translations[loc];
        return {
          id: loc,
          label: loc.toUpperCase(),
          content: (
            <div className={styles.localePanel}>
              {!readOnly && loc !== 'en' && onCopyFromLocale ? (
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  disabled={busy}
                  onClick={() => onCopyFromLocale('en')}
                >
                  {t('form.copyFromEn')}
                </Button>
              ) : null}

              {!readOnly ? (
                <Select
                  label={t('form.insertTemplate')}
                  value=""
                  options={[
                    { value: '', label: t('form.templatePlaceholder') },
                    ...NEWS_CONTENT_TEMPLATE_OPTIONS.filter((id) => id !== 'blank').map((id) => ({
                      value: id,
                      label: t(`templates.${id}`),
                    })),
                  ]}
                  onChange={(e) => {
                    const templateId = e.target.value as NewsContentTemplateId;
                    if (!templateId) return;
                    setPendingTemplate({ id: templateId, loc });
                  }}
                  disabled={busy}
                />
              ) : null}

              <Input
                label={t('form.title')}
                value={content.title}
                onChange={(e) =>
                  onChange('translations', {
                    ...values.translations,
                    [loc]: { ...content, title: e.target.value },
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
                      [loc]: { ...content, excerpt: e.target.value },
                    })
                  }
                  disabled={busy || readOnly}
                  maxLength={500}
                />
              </label>
            </div>
          ),
        };
      }),
    [busy, onChange, onCopyFromLocale, readOnly, t, values.translations],
  );

  return (
    <div className={styles.root}>
      <NewsLocaleCompleteness values={values} hasCover={hasCover} media={media} activeLocale={locale} />

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
      <DateTimePicker
        label={t('form.scheduledAt')}
        helperText={t('form.scheduledAtHint')}
        value={values.scheduledAt}
        onValueChange={(next) => onChange('scheduledAt', next)}
        disabled={busy || readOnly || status === 'published'}
      />
      <Checkbox
        label={t('form.featured')}
        checked={values.featured}
        onChange={(e) => onChange('featured', e.target.checked)}
        disabled={busy || readOnly}
      />

      <Tabs
        items={localeTabs}
        value={locale}
        onValueChange={(id) => onLocaleChange(id as NewsFormLocale)}
        ariaLabel={t('form.locales')}
      />

      <ConfirmDialog
        open={pendingTemplate !== null}
        title={t('confirm.templateTitle')}
        description={t('confirm.templateBody', {
          count: pendingTemplate
            ? applyContentTemplate(pendingTemplate.id, pendingTemplate.loc).length
            : 0,
        })}
        confirmLabel={t('confirm.templateConfirm')}
        onConfirm={() => {
          if (!pendingTemplate) return;
          const content = values.translations[pendingTemplate.loc];
          onChange('translations', {
            ...values.translations,
            [pendingTemplate.loc]: {
              ...content,
              body: applyContentTemplate(pendingTemplate.id, pendingTemplate.loc),
            },
          });
          setPendingTemplate(null);
        }}
        onClose={() => setPendingTemplate(null)}
      />
    </div>
  );
}
