'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Checkbox, ConfirmDialog, DateTimePicker, Input, Select } from '@/components/ui';
import {
  applyContentTemplate,
  NEWS_CONTENT_TEMPLATE_OPTIONS,
  type NewsContentTemplateId,
} from '../lib/news-content-templates';
import type { NewsFormLocale, NewsPostFormValues } from '../types';
import { NEWS_CATEGORIES } from '../types';
import { NewsLocaleCompleteness } from './news-locale-completeness';
import type { NewsMediaDto } from '../news-api-types';
import styles from './news-post-settings-panel.module.css';

type NewsPostSettingsPanelProps = {
  values: NewsPostFormValues;
  locale: NewsFormLocale;
  media: NewsMediaDto[];
  status: string;
  busy: boolean;
  readOnly: boolean;
  hasCover: boolean;
  embedded?: boolean;
  onChange: <K extends keyof NewsPostFormValues>(key: K, value: NewsPostFormValues[K]) => void;
  onCopyFromLocale?: (source: NewsFormLocale) => void;
};

export function NewsPostSettingsPanel({
  values,
  locale,
  media,
  status,
  busy,
  readOnly,
  hasCover,
  embedded = false,
  onChange,
  onCopyFromLocale,
}: NewsPostSettingsPanelProps) {
  const t = useTranslations('news');
  const [pendingTemplate, setPendingTemplate] = useState<{ id: NewsContentTemplateId; loc: NewsFormLocale } | null>(null);

  return (
    <section className={styles.root} aria-label={t('form.settingsLabel')}>
      {!embedded ? (
        <div className={styles.header}>
          <h3 className={styles.title}>{t('form.settingsLabel')}</h3>
          <p className={styles.description}>{t('form.settingsDescription')}</p>
        </div>
      ) : null}

      {!embedded ? (
        <NewsLocaleCompleteness values={values} hasCover={hasCover} media={media} activeLocale={locale} />
      ) : null}

      {!readOnly && locale !== 'en' && onCopyFromLocale ? (
        <div className={styles.actions}>
          <Button type="button" variant="outline" size="sm" disabled={busy} onClick={() => onCopyFromLocale('en')}>
            {t('form.copyFromEn')}
          </Button>
        </div>
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
            setPendingTemplate({ id: templateId, loc: locale });
          }}
          disabled={busy}
        />
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

      <ConfirmDialog
        open={pendingTemplate !== null}
        title={t('confirm.templateTitle')}
        description={t('confirm.templateBody', {
          count: pendingTemplate ? applyContentTemplate(pendingTemplate.id, pendingTemplate.loc).length : 0,
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
    </section>
  );
}
