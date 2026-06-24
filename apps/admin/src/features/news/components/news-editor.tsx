'use client';

import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { Button, Card, ConfirmDialog, PageHeader, useToast } from '@/components/ui';
import { useUnsavedChangesGuard } from '@/features/admin-shell/hooks/use-unsaved-changes-guard';
import { useNewsAutosave } from '../hooks/use-news-autosave';
import { useNewsPostForm } from '../hooks/use-news-post-form';
import { useNewsPostMutations } from '../hooks/use-news-post-mutations';
import { copyLocaleFromSource } from '../lib/copy-locale-content';
import { mediaReferencedInBody } from '../lib/news-locale-utils';
import type { NewsPostAdminDto } from '../news-api-types';
import type { NewsFormLocale } from '../types';
import { postToFormValues } from '../types';
import { NewsEditorMetaPanel } from './news-editor-meta-panel';
import { NewsLivePreview } from './news-live-preview';
import { insertMediaBlock, NewsMediaLibrary } from './news-media-library';
import { NewsPostForm } from './news-post-form';
import { NewsPublishChecklistDialog } from './news-publish-checklist-dialog';
import { NewsRevisionPanel } from './news-revision-panel';
import { NewsSeoPreview } from './news-seo-preview';
import styles from './news-editor.module.css';

type NewsEditorProps = {
  post: NewsPostAdminDto;
  canWriteNews: boolean;
};

export function NewsEditor({ post: initialPost, canWriteNews }: NewsEditorProps) {
  const t = useTranslations('news');
  const router = useRouter();
  const { showToast } = useToast();
  const [post, setPost] = useState(initialPost);
  const [locale, setLocale] = useState<NewsFormLocale>('en');
  const [previewOpen, setPreviewOpen] = useState(false);
  const form = useNewsPostForm(postToFormValues(post));
  const readOnly = !canWriteNews;

  useUnsavedChangesGuard(form.dirty);

  const mutations = useNewsPostMutations({
    post,
    form,
    locale,
    onPostChange: setPost,
    onDeleted: () => router.push('/dashboard/news'),
  });

  const autosave = useNewsAutosave({
    dirty: form.dirty,
    readOnly,
    values: form.values,
    save: mutations.save,
  });

  const categoryLabel = t(`category.${form.values.category}`);

  const statusDescription = useMemo(
    () =>
      [
        t('editor.status', { status: t(`status.${post.status}`) }),
        autosave.statusLabel,
        mutations.busy && !autosave.statusLabel ? t('editor.saving') : '',
      ]
        .filter(Boolean)
        .join(' · '),
    [autosave.statusLabel, mutations.busy, post.status, t],
  );

  const handleDeleteMedia = useCallback(
    (mediaId: string) => {
      const inBody = mediaReferencedInBody(mediaId, form.values.translations);
      void mutations.removeMedia(mediaId, inBody);
    },
    [form.values.translations, mutations],
  );

  const handleInsertMedia = useCallback(
    (mediaId: string, kind: 'inline_image' | 'inline_video') => {
      const loc = form.values.translations[locale];
      form.onChange('translations', {
        ...form.values.translations,
        [locale]: {
          ...loc,
          body: insertMediaBlock(loc.body, mediaId, kind),
        },
      });
    },
    [form, locale],
  );

  const handleAltTextChange = useCallback(
    (mediaId: string, altLocale: NewsFormLocale, value: string) => {
      const item = post.media.find((m) => m.id === mediaId);
      const nextAlt = { ...(item?.altText ?? {}), [altLocale]: value };
      void mutations.updateMediaAlt(mediaId, nextAlt);
    },
    [mutations, post.media],
  );

  const handleRestored = useCallback(
    (updated: NewsPostAdminDto) => {
      setPost(updated);
      form.reset(postToFormValues(updated));
    },
    [form],
  );

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (readOnly || mutations.busy) return;
      const mod = e.metaKey || e.ctrlKey;
      if (mod && e.key === 's') {
        e.preventDefault();
        void mutations.save();
      }
      if (mod && e.shiftKey && e.key === 'p') {
        e.preventDefault();
        mutations.requestPublish();
      }
    }
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [mutations, readOnly]);

  return (
    <div className={styles.root}>
      <PageHeader
        title={post.translations.en.title || post.slug}
        description={statusDescription}
        actions={
          readOnly ? (
            <Button variant="outline" onClick={() => router.push('/dashboard/news')}>
              {t('actions.back')}
            </Button>
          ) : (
            <div className={styles.actions}>
              <Button variant="outline" onClick={() => router.push('/dashboard/news')} disabled={mutations.busy}>
                {t('actions.back')}
              </Button>
              <Button
                variant="outline"
                className={styles.previewToggle}
                onClick={() => setPreviewOpen((v) => !v)}
              >
                {t('preview.toggle')}
              </Button>
              <Button onClick={() => void mutations.save()} disabled={mutations.busy || !form.dirty}>
                {t('actions.save')}
              </Button>
              {post.status !== 'published' ? (
                <Button onClick={mutations.requestPublish} disabled={mutations.busy}>
                  {t('actions.publish')}
                </Button>
              ) : (
                <Button variant="outline" onClick={mutations.requestUnpublish} disabled={mutations.busy}>
                  {t('actions.unpublish')}
                </Button>
              )}
              <Button variant="ghost" onClick={mutations.requestArchive} disabled={mutations.busy}>
                {t('actions.archive')}
              </Button>
              <Button variant="ghost" onClick={() => mutations.setDeleteOpen(true)} disabled={mutations.busy}>
                {t('actions.delete')}
              </Button>
            </div>
          )
        }
      />

      {readOnly ? (
        <p className={styles.readOnlyBanner} role="note">
          {t('editor.readOnlyBanner')}
        </p>
      ) : null}

      <div className={styles.editorGrid}>
        <Card padding="md" className={styles.formColumn}>
          <NewsPostForm
            values={form.values}
            locale={locale}
            media={post.media}
            status={post.status}
            busy={mutations.busy}
            readOnly={readOnly}
            hasCover={Boolean(post.coverMediaId)}
            onLocaleChange={setLocale}
            onChange={form.onChange}
            onBodyChange={(blocks) =>
              form.onChange('translations', {
                ...form.values.translations,
                [locale]: { ...form.values.translations[locale], body: blocks },
              })
            }
            onCopyFromLocale={(source) => {
              form.onChange('translations', copyLocaleFromSource(form.values, source, locale));
              showToast({ tone: 'success', title: t('toast.copiedLocale'), message: '' });
            }}
          />
          {!readOnly ? (
            <NewsMediaLibrary
              media={post.media}
              readOnly={readOnly}
              busy={mutations.busy}
              onInsert={handleInsertMedia}
              onDelete={handleDeleteMedia}
              onUploadCover={(file) => void mutations.uploadCover(file)}
              onUploadInline={(file, kind) => void mutations.uploadInline(file, kind)}
              onAltTextChange={handleAltTextChange}
            />
          ) : null}
        </Card>

        <div className={`${styles.previewColumn} ${previewOpen ? styles.previewColumnOpen : ''}`}>
          <NewsLivePreview
            values={form.values}
            locale={locale}
            media={post.media}
            coverImageUrl={post.coverImageUrl}
            status={post.status}
            categoryLabel={categoryLabel}
          />
        </div>

        <aside className={styles.sidebar}>
          <NewsEditorMetaPanel post={post} locale={locale} />
          <NewsSeoPreview
            postId={post.id}
            values={form.values}
            locale={locale}
            coverImageUrl={post.coverImageUrl}
            publishedAt={post.publishedAt}
          />
          <NewsRevisionPanel postId={post.id} readOnly={readOnly} onRestored={handleRestored} />
        </aside>
      </div>

      <NewsPublishChecklistDialog
        open={mutations.publishOpen}
        values={form.values}
        hasCover={Boolean(post.coverMediaId)}
        onClose={() => mutations.setPublishOpen(false)}
        onConfirm={() => void mutations.confirmPublish()}
        onGoToLocale={setLocale}
      />
      <ConfirmDialog
        open={mutations.unpublishOpen}
        title={t('confirm.unpublishTitle')}
        description={t('confirm.unpublishBody')}
        confirmLabel={t('actions.unpublish')}
        onConfirm={() => void mutations.confirmUnpublish()}
        onClose={() => mutations.setUnpublishOpen(false)}
      />
      <ConfirmDialog
        open={mutations.archiveOpen}
        title={t('confirm.archiveTitle')}
        description={t('confirm.archiveBody')}
        confirmLabel={t('actions.archive')}
        onConfirm={() => void mutations.confirmArchive()}
        onClose={() => mutations.setArchiveOpen(false)}
      />
      <ConfirmDialog
        open={mutations.deleteOpen}
        title={t('delete.title')}
        description={t('delete.body')}
        confirmLabel={t('delete.confirm')}
        tone="danger"
        onConfirm={() => void mutations.confirmDelete()}
        onClose={() => mutations.setDeleteOpen(false)}
      />
    </div>
  );
}
