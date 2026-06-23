'use client';

import Image from 'next/image';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { useState } from 'react';
import { Button, Card, ConfirmDialog, PageHeader, useToast } from '@/components/ui';
import { Can } from '@/lib/auth/rbac';
import { useWorkspaceRefresh } from '@/features/admin-shell/hooks/use-workspace-refresh';
import {
  archiveNewsPost,
  deleteNewsPost,
  fetchNewsPost,
  publishNewsPost,
  unpublishNewsPost,
  updateNewsPost,
  uploadNewsMedia,
} from '../data/news-adapter-client';
import { useNewsPostForm } from '../hooks/use-news-post-form';
import type { NewsBodyBlock, NewsPostAdminDto } from '../news-api-types';
import type { NewsFormLocale } from '../types';
import { postToFormValues } from '../types';
import { NewsPostForm } from './news-post-form';
import styles from './news-editor.module.css';

type NewsEditorProps = {
  post: NewsPostAdminDto;
};

export function NewsEditor({ post: initialPost }: NewsEditorProps) {
  const t = useTranslations('news');
  const { showToast } = useToast();
  const router = useRouter();
  const { refresh } = useWorkspaceRefresh();
  const [post, setPost] = useState(initialPost);
  const [locale, setLocale] = useState<NewsFormLocale>('en');
  const [busy, setBusy] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const form = useNewsPostForm(postToFormValues(post));

  async function save() {
    setBusy(true);
    try {
      const updated = await updateNewsPost(post.id, {
        slug: form.values.slug,
        category: form.values.category,
        translations: form.values.translations,
        scheduledAt: form.values.scheduledAt || null,
      });
      setPost(updated);
      form.reset(postToFormValues(updated));
      showToast({ tone: 'success', title: t('toast.saved'), message: '' });
      refresh();
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

  async function runAction(action: () => Promise<NewsPostAdminDto>, successKey: string) {
    setBusy(true);
    try {
      const updated = await action();
      setPost(updated);
      form.reset(postToFormValues(updated));
      showToast({ tone: 'success', title: t(successKey), message: '' });
      refresh();
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

  async function reloadPost() {
    const updated = await fetchNewsPost(post.id);
    setPost(updated);
    form.reset(postToFormValues(updated));
    refresh();
  }

  async function handleUploadCover(file: File) {
    setBusy(true);
    try {
      await uploadNewsMedia(post.id, 'cover', file);
      await reloadPost();
      showToast({ tone: 'success', title: t('toast.mediaUploaded'), message: '' });
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

  async function handleUploadInline(file: File, kind: 'inline_image' | 'inline_video') {
    setBusy(true);
    try {
      const result = (await uploadNewsMedia(post.id, kind, file)) as { id: string };
      const mediaId = result.id;
      const loc = form.values.translations[locale];
      const block: NewsBodyBlock =
        kind === 'inline_video' ? { type: 'video', mediaId } : { type: 'image', mediaId };
      form.onChange('translations', {
        ...form.values.translations,
        [locale]: { ...loc, body: [...loc.body, block] },
      });
      await reloadPost();
      showToast({ tone: 'success', title: t('toast.mediaUploaded'), message: '' });
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
      <PageHeader
        title={post.translations.en.title || post.slug}
        description={t('editor.status', { status: t(`status.${post.status}`) })}
        actions={
          <div className={styles.actions}>
            <Button variant="outline" onClick={() => router.push('/dashboard/news')} disabled={busy}>
              {t('actions.back')}
            </Button>
            <Can permission="news:write">
              <Button onClick={() => void save()} disabled={busy}>
                {t('actions.save')}
              </Button>
              {post.status !== 'published' ? (
                <Button
                  onClick={() => void runAction(() => publishNewsPost(post.id), 'toast.published')}
                  disabled={busy}
                >
                  {t('actions.publish')}
                </Button>
              ) : (
                <Button
                  variant="outline"
                  onClick={() => void runAction(() => unpublishNewsPost(post.id), 'toast.unpublished')}
                  disabled={busy}
                >
                  {t('actions.unpublish')}
                </Button>
              )}
              <Button
                variant="ghost"
                onClick={() => void runAction(() => archiveNewsPost(post.id), 'toast.archived')}
                disabled={busy}
              >
                {t('actions.archive')}
              </Button>
              <Button variant="ghost" onClick={() => setDeleteOpen(true)} disabled={busy}>
                {t('actions.delete')}
              </Button>
            </Can>
          </div>
        }
      />
      {post.coverImageUrl ? (
        <div className={styles.coverPreview}>
          <Image src={post.coverImageUrl} alt="" fill className={styles.coverImage} unoptimized />
        </div>
      ) : null}
      <Card padding="md">
        <NewsPostForm
          values={form.values}
          locale={locale}
          media={post.media}
          status={post.status}
          busy={busy}
          onLocaleChange={setLocale}
          onChange={form.onChange}
          onBodyChange={(blocks) =>
            form.onChange('translations', {
              ...form.values.translations,
              [locale]: { ...form.values.translations[locale], body: blocks },
            })
          }
          onUploadCover={handleUploadCover}
          onUploadInline={handleUploadInline}
        />
      </Card>
      <ConfirmDialog
        open={deleteOpen}
        title={t('delete.title')}
        description={t('delete.body')}
        confirmLabel={t('delete.confirm')}
        tone="danger"
        onConfirm={async () => {
          setDeleteOpen(false);
          setBusy(true);
          try {
            await deleteNewsPost(post.id);
            showToast({ tone: 'success', title: t('toast.deleted'), message: '' });
            router.push('/dashboard/news');
          } catch (e) {
            showToast({
              tone: 'error',
              title: t('toast.error'),
              message: e instanceof Error ? e.message : '',
            });
          } finally {
            setBusy(false);
          }
        }}
        onClose={() => setDeleteOpen(false)}
      />
    </div>
  );
}
