'use client';

import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Button, ConfirmDialog, PageHeader, useToast } from '@/components/ui';
import { useUnsavedChangesGuard } from '@/features/admin-shell/hooks/use-unsaved-changes-guard';
import { useNewsAltTextSave } from '../hooks/use-news-alt-text-save';
import { useNewsAutosave } from '../hooks/use-news-autosave';
import { useNewsPostForm } from '../hooks/use-news-post-form';
import { useNewsPostMutations } from '../hooks/use-news-post-mutations';
import { updateNewsMediaAlt } from '../data/news-adapter-client';
import { copyLocaleFromSource } from '../lib/copy-locale-content';
import { newsFormEditorFingerprint } from '../lib/news-save-payload';
import { newsApiErrorMessage } from '../lib/news-api-messages';
import { mediaReferencedInBody } from '../lib/news-locale-utils';
import type { NewsPostAdminDto } from '../news-api-types';
import type { NewsFormLocale } from '../types';
import { postToFormValues } from '../types';
import { NewsBlockList } from './news-block-list';
import { NewsCoverHero } from './news-cover-hero';
import { NewsDocumentShell } from './news-document-shell';
import documentStyles from './news-document-shell.module.css';
import { NewsInspectorDrawer } from './news-inspector-drawer';
import { NewsInspectorPanels } from './news-inspector-panels';
import { useNewsPreviewSync } from '../hooks/use-news-preview-sync';
import { NewsEditorViewTabs, type NewsEditorView } from './news-editor-view-tabs';
import { NewsLivePreview } from './news-live-preview';
import { insertMediaBlockAt } from './news-media-library';
import { NewsDocumentHeader } from './news-document-header';
import { NewsDocumentEditorProvider } from '../context/news-document-editor-context';
import { mergeBlocksAtIndex, NewsDocumentToolbar } from './news-document-toolbar';
import { NewsPublishChecklistDialog } from './news-publish-checklist-dialog';
import { countIncompleteLocales } from '../lib/news-locale-utils';
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
  const [editorView, setEditorView] = useState<NewsEditorView>('write');
  const form = useNewsPostForm(postToFormValues(post));
  const readOnly = !canWriteNews;
  const savedFingerprintRef = useRef(newsFormEditorFingerprint(postToFormValues(initialPost)));

  useEffect(() => {
    savedFingerprintRef.current = newsFormEditorFingerprint(postToFormValues(post));
  }, [post]);

  const contentDirty = useMemo(
    () => newsFormEditorFingerprint(form.values) !== savedFingerprintRef.current,
    [form.values],
  );

  const persistAltText = useCallback(
    async (mediaId: string, altText: Partial<Record<NewsFormLocale, string>>) => {
      await updateNewsMediaAlt(mediaId, altText);
    },
    [],
  );

  const handleAltSaveError = useCallback(
    (error: unknown) => {
      showToast({
        tone: 'error',
        title: t('toast.error'),
        message: newsApiErrorMessage(error, t, t('toast.altSaveFailed')),
      });
    },
    [showToast, t],
  );

  const { scheduleAltSave, flushAltSaves, altPending } = useNewsAltTextSave(persistAltText, {
    onError: handleAltSaveError,
  });

  useUnsavedChangesGuard(contentDirty || altPending, t('editor.unsavedLeaveConfirm'));

  const mutations = useNewsPostMutations({
    post,
    form,
    locale,
    isDirty: () => contentDirty || altPending,
    onPostChange: setPost,
    onDeleted: () => router.push('/dashboard/news'),
    flushBeforeAction: flushAltSaves,
  });

  const autosave = useNewsAutosave({
    dirty: contentDirty,
    readOnly,
    values: form.values,
    save: mutations.save,
    hasCover: Boolean(post.coverMediaId),
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

  const handleInsertMediaAt = useCallback(
    (mediaId: string, kind: 'inline_image' | 'inline_video', insertIndex: number) => {
      const loc = form.values.translations[locale];
      form.onChange('translations', {
        ...form.values.translations,
        [locale]: {
          ...loc,
          body: insertMediaBlockAt(loc.body, mediaId, kind, insertIndex),
        },
      });
    },
    [form, locale],
  );

  const handleAltTextChange = useCallback(
    (mediaId: string, altLocale: NewsFormLocale, value: string) => {
      const item = post.media.find((m) => m.id === mediaId);
      const nextAlt = { ...(item?.altText ?? {}), [altLocale]: value };
      setPost((prev) => ({
        ...prev,
        media: prev.media.map((m) => (m.id === mediaId ? { ...m, altText: nextAlt } : m)),
      }));
      scheduleAltSave(mediaId, altLocale, nextAlt);
    },
    [post.media, scheduleAltSave],
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
      if (mod && e.shiftKey && e.key === 'v') {
        e.preventDefault();
        setEditorView((v) => (v === 'preview' ? 'write' : 'preview'));
      }
    }
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [mutations, readOnly]);

  const localeContent = form.values.translations[locale];

  const coverAltText = useMemo(() => {
    if (!post.coverMediaId) return null;
    const cover = post.media.find((m) => m.id === post.coverMediaId);
    if (!cover?.altText) return null;
    return cover.altText[locale]?.trim() || cover.altText.en?.trim() || null;
  }, [locale, post.coverMediaId, post.media]);

  const incompleteLocaleCount = useMemo(
    () => countIncompleteLocales(form.values, Boolean(post.coverMediaId), post.media),
    [form.values, post.coverMediaId, post.media],
  );

  const inspectorPanels = (
    <NewsInspectorPanels
      postId={post.id}
      post={post}
      values={form.values}
      locale={locale}
      readOnly={readOnly}
      busy={mutations.busy}
      lifecycleBusy={mutations.lifecycleBusy}
      hasCover={Boolean(post.coverMediaId)}
      coverImageUrl={post.coverImageUrl}
      coverMediaId={post.coverMediaId}
      contentDirty={contentDirty}
      altPending={altPending}
      media={post.media}
      bodyBlockCount={localeContent.body.length}
      onChange={form.onChange}
      onCopyFromLocale={(source) => {
        form.onChange('translations', copyLocaleFromSource(form.values, source, locale));
        showToast({ tone: 'success', title: t('toast.copiedLocale'), message: '' });
      }}
      onInsertMediaAt={handleInsertMediaAt}
      onDeleteMedia={handleDeleteMedia}
      onAltTextChange={handleAltTextChange}
      onBeforeRestore={flushAltSaves}
      onRestored={handleRestored}
    />
  );

  useNewsPreviewSync({
    postId: post.id,
    locale,
    values: form.values,
    media: post.media,
    coverImageUrl: post.coverImageUrl,
    coverMediaId: post.coverMediaId,
    status: post.status,
  });

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
                onClick={() => setEditorView((v) => (v === 'preview' ? 'write' : 'preview'))}
              >
                {editorView === 'preview' ? t('editor.writeTab') : t('editor.previewTab')}
              </Button>
              <Button onClick={() => void mutations.save()} disabled={mutations.busy || !contentDirty}>
                {t('actions.save')}
              </Button>
              {autosave.canRetry ? (
                <Button variant="outline" onClick={() => void autosave.retrySave()} disabled={mutations.busy}>
                  {t('autosave.retry')}
                </Button>
              ) : null}
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

      <NewsDocumentEditorProvider>
      <NewsDocumentShell
        document={
          <NewsEditorViewTabs
            view={editorView}
            postId={post.id}
            locale={locale}
            onViewChange={setEditorView}
            writePanel={
              <>
                {!readOnly ? (
                  <NewsDocumentToolbar
                    readOnly={readOnly}
                    busy={mutations.lifecycleBusy}
                    bodyLength={localeContent.body.length}
                    onInsertBlocks={(blocks, insertIndex) => {
                      form.onChange('translations', {
                        ...form.values.translations,
                        [locale]: {
                          ...localeContent,
                          body: mergeBlocksAtIndex(localeContent.body, insertIndex, blocks),
                        },
                      });
                    }}
                    onUploadCover={(file) => void mutations.uploadCover(file)}
                    onUploadInlineAt={(file, kind, insertIndex) =>
                      void mutations.uploadInlineAt(file, kind, insertIndex)
                    }
                    onBlockLimit={() =>
                      showToast({
                        tone: 'warning',
                        title: t('toast.validationTitle'),
                        message: t('validation.blockLimit'),
                      })
                    }
                  />
                ) : null}
                <div className={documentStyles.proseDocument}>
                <NewsCoverHero
                  coverImageUrl={post.coverImageUrl}
                  coverAttached={Boolean(post.coverMediaId)}
                  readOnly={readOnly}
                  uploadBusy={mutations.uploadingKind === 'cover'}
                  uploadError={mutations.uploadValidationErrors.cover ?? null}
                  onUpload={(file) => void mutations.uploadCover(file)}
                />
                <NewsDocumentHeader
                  values={form.values}
                  locale={locale}
                  media={post.media}
                  hasCover={Boolean(post.coverMediaId)}
                  busy={mutations.lifecycleBusy}
                  readOnly={readOnly}
                  onLocaleChange={setLocale}
                  onChange={form.onChange}
                />
                <NewsBlockList
                  blocks={localeContent.body}
                  locale={locale}
                  media={post.media}
                  readOnly={readOnly}
                  actionsDisabled={mutations.lifecycleBusy}
                  documentMode
                  uploadingBlockKind={
                    mutations.uploadingKind === 'inline_image' || mutations.uploadingKind === 'inline_video'
                      ? mutations.uploadingKind
                      : null
                  }
                  uploadingGallerySlot={mutations.uploadingGallerySlot}
                  blockUploadPreview={mutations.blockUploadPreview}
                  uploadValidationErrors={mutations.uploadValidationErrors}
                  onChange={(body) =>
                    form.onChange('translations', {
                      ...form.values.translations,
                      [locale]: { ...localeContent, body },
                    })
                  }
                  onUploadForBlock={(blockIndex, file, blockType) =>
                    void mutations.uploadForBlock(
                      blockIndex,
                      file,
                      blockType === 'video' ? 'inline_video' : 'inline_image',
                    )
                  }
                  onUploadForGallerySlot={(blockIndex, itemIndex, file) =>
                    void mutations.uploadForGallerySlot(blockIndex, itemIndex, file)
                  }
                />
                </div>
              </>
            }
            previewPanel={
              <NewsLivePreview
                values={form.values}
                locale={locale}
                media={post.media}
                coverImageUrl={post.coverImageUrl}
                coverAltText={coverAltText}
                status={post.status}
                categoryLabel={categoryLabel}
                fullPage
              />
            }
          />
        }
        inspector={
          <NewsInspectorDrawer incompleteLocaleCount={incompleteLocaleCount}>
            {inspectorPanels}
          </NewsInspectorDrawer>
        }
      />
      </NewsDocumentEditorProvider>

      <NewsPublishChecklistDialog
        open={mutations.publishOpen}
        values={form.values}
        hasCover={Boolean(post.coverMediaId)}
        dirty={contentDirty || altPending}
        media={post.media}
        onClose={() => mutations.setPublishOpen(false)}
        onConfirm={() => void mutations.confirmPublish()}
        onSaveAndPublish={() => void mutations.saveAndPublish()}
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
