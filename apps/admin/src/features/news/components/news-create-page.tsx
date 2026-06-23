'use client';

import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { useState } from 'react';
import { Button, Card, Input, PageHeader, Select, useToast } from '@/components/ui';
import { createNewsPost } from '../data/news-adapter-client';
import { useNewsPostForm } from '../hooks/use-news-post-form';
import { NEWS_CATEGORIES } from '../types';
import styles from './news-create.module.css';

export function NewsCreatePage() {
  const t = useTranslations('news');
  const { showToast } = useToast();
  const router = useRouter();
  const form = useNewsPostForm();
  const [busy, setBusy] = useState(false);

  async function handleCreate() {
    setBusy(true);
    try {
      const slug = form.values.slug.trim();
      const created = await createNewsPost({
        ...(slug ? { slug } : {}),
        category: form.values.category,
        translations: form.values.translations,
      });
      showToast({ tone: 'success', title: t('toast.created'), message: '' });
      router.push(`/dashboard/news/${created.id}`);
    } catch (e) {
      showToast({
        tone: 'error',
        title: t('toast.error'),
        message: e instanceof Error ? e.message : '',
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
