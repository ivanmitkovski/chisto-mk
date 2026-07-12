'use client';

import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { useState } from 'react';
import { Button, Card, Input, PageHeader, Select, useToast } from '@/components/ui';
import { createNewsPost } from '../data/news-adapter-client';
import {
  applyContentTemplate,
  NEWS_CONTENT_TEMPLATE_OPTIONS,
  type NewsContentTemplateId,
} from '../lib/news-content-templates';
import { useNewsPostForm } from '../hooks/use-news-post-form';
import { newsApiErrorMessage } from '../lib/news-api-messages';
import { NEWS_CATEGORIES } from '../types';
import styles from './news-create.module.css';

export function NewsCreatePage() {
  const t = useTranslations('news');
  const { showToast } = useToast();
  const router = useRouter();
  const form = useNewsPostForm();
  const [busy, setBusy] = useState(false);
  const [templateId, setTemplateId] = useState<NewsContentTemplateId>('blank');

  function applyTemplate(nextId: NewsContentTemplateId) {
    setTemplateId(nextId);
    const locales = ['en', 'mk', 'sq'] as const;
    const translations = { ...form.values.translations };
    for (const loc of locales) {
      translations[loc] = {
        ...translations[loc],
        body: applyContentTemplate(nextId, loc),
      };
    }
    form.onChange('translations', translations);
    if (nextId !== 'blank') {
      form.onChange('category', nextId);
    }
  }

  async function handleCreate() {
    const enTitle = form.values.translations.en.title.trim();
    if (!enTitle) {
      showToast({
        tone: 'warning',
        title: t('toast.validationTitle'),
        message: t('validation.localeTitleRequired'),
      });
      return;
    }

    setBusy(true);
    try {
      const created = await createNewsPost(form.values);
      showToast({ tone: 'success', title: t('toast.created'), message: '' });
      router.push(`/dashboard/news/${created.id}`);
    } catch (e) {
      showToast({
        tone: 'error',
        title: t('toast.error'),
        message: newsApiErrorMessage(e, t, t('toast.error')),
      });
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className={styles.root}>
      <PageHeader title={t('create.title')} description={t('create.description')} />
      <Card padding="md">
        <div className={styles.fields}>
          <Input
            label={t('form.slug')}
            value={form.values.slug}
            onChange={(e) => form.onChange('slug', e.target.value)}
            disabled={busy}
            placeholder={t('create.slugPlaceholder')}
          />
          <Select
            label={t('form.category')}
            value={form.values.category}
            options={NEWS_CATEGORIES.map((c) => ({ value: c, label: t(`category.${c}`) }))}
            onChange={(e) =>
              form.onChange('category', e.target.value as typeof form.values.category)
            }
            disabled={busy}
          />
          <Select
            label={t('create.templateLabel')}
            value={templateId}
            options={NEWS_CONTENT_TEMPLATE_OPTIONS.map((id) => ({
              value: id,
              label: id === 'blank' ? t('create.templateNone') : t(`templates.${id}`),
            }))}
            onChange={(e) => applyTemplate(e.target.value as NewsContentTemplateId)}
            disabled={busy}
          />
          <Input
            label={t('form.title')}
            value={form.values.translations.en.title}
            onChange={(e) =>
              form.onChange('translations', {
                ...form.values.translations,
                en: { ...form.values.translations.en, title: e.target.value },
              })
            }
            disabled={busy}
            required
          />
        </div>
        <div className={styles.actions}>
          <Button variant="outline" onClick={() => router.push('/dashboard/news')} disabled={busy}>
            {t('actions.back')}
          </Button>
          <Button onClick={() => void handleCreate()} disabled={busy}>
            {t('actions.createDraft')}
          </Button>
        </div>
      </Card>
    </div>
  );
}
