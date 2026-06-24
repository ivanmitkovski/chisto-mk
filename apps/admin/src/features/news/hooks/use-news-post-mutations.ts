'use client';

import { useCallback, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { useWorkspaceRefresh } from '@/features/admin-shell/hooks/use-workspace-refresh';
import {
  archiveNewsPost,
  deleteNewsMedia,
  deleteNewsPost,
  fetchNewsPost,
  publishNewsPost,
  unpublishNewsPost,
  updateNewsMediaAlt,
  updateNewsPost,
  uploadNewsMedia,
} from '../data/news-adapter-client';
import { ApiError } from '@/lib/api';
import type { NewsLocale } from '../news-api-types';
import { newsApiErrorMessage } from '../lib/news-api-messages';
import { validateNewsPostForm } from '../lib/news-post-policy';
import type { NewsBodyBlock, NewsPostAdminDto } from '../news-api-types';
import type { NewsFormLocale, NewsPostFormValues } from '../types';
import { postToFormValues } from '../types';

type FormApi = {
  values: NewsPostFormValues;
  dirty: boolean;
  reset: (next: NewsPostFormValues) => void;
  onChange: <K extends keyof NewsPostFormValues>(key: K, value: NewsPostFormValues[K]) => void;
};

type UseNewsPostMutationsOptions = {
  post: NewsPostAdminDto;
  form: FormApi;
  locale: NewsFormLocale;
  onPostChange: (post: NewsPostAdminDto) => void;
  onDeleted?: () => void;
};

export function useNewsPostMutations({
  post,
  form,
  locale,
  onPostChange,
  onDeleted,
}: UseNewsPostMutationsOptions) {
  const t = useTranslations('news');
  const { showToast } = useToast();
  const { refresh } = useWorkspaceRefresh();
  const [busy, setBusy] = useState(false);
  const [publishOpen, setPublishOpen] = useState(false);
  const [unpublishOpen, setUnpublishOpen] = useState(false);
  const [archiveOpen, setArchiveOpen] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);

  const reloadLatest = useCallback(async () => {
    const updated = await fetchNewsPost(post.id);
    onPostChange(updated);
    form.reset(postToFormValues(updated));
    refresh();
  }, [form, onPostChange, post.id, refresh]);

  const showError = useCallback(
    (error: unknown) => {
      showToast({
        tone: 'error',
        title: t('toast.error'),
        message: newsApiErrorMessage(error, t, t('toast.error')),
      });
    },
    [showToast, t],
  );

  const mergePostMedia = useCallback(
    async (preserveForm: boolean) => {
      const updated = await fetchNewsPost(post.id);
      onPostChange(updated);
      if (!preserveForm) {
        form.reset(postToFormValues(updated));
      }
      refresh();
      return updated;
    },
    [form, onPostChange, post.id, refresh],
  );

  const blockIfDirty = useCallback((): boolean => {
    if (!form.dirty) return false;
    showToast({
      tone: 'warning',
      title: t('toast.unsavedTitle'),
      message: t('toast.unsavedMessage'),
    });
    return true;
  }, [form.dirty, showToast, t]);

  const save = useCallback(
    async (options?: { silent?: boolean }): Promise<boolean> => {
      const validationError = validateNewsPostForm(form.values, { mode: 'save' });
      if (validationError) {
        if (!options?.silent) {
          showToast({
            tone: 'warning',
            title: t('toast.validationTitle'),
            message: t(`validation.${validationError}`),
          });
        }
        return false;
      }

      setBusy(true);
      try {
        const latest = await fetchNewsPost(post.id);
        if (latest.updatedAt !== post.updatedAt) {
          showToast({
            tone: 'warning',
            title: t('toast.conflictTitle'),
            message: t('toast.conflictMessage'),
          });
          await reloadLatest();
          return false;
        }

        const updated = await updateNewsPost(post.id, {
          slug: form.values.slug,
          category: form.values.category,
          translations: form.values.translations,
          scheduledAt: form.values.scheduledAt || null,
          featured: form.values.featured,
        });
        onPostChange(updated);
        form.reset(postToFormValues(updated));
        if (!options?.silent) {
          showToast({ tone: 'success', title: t('toast.saved'), message: '' });
        }
        refresh();
        return true;
      } catch (error) {
        if (error instanceof ApiError && error.status === 409) {
          showToast({
            tone: 'warning',
            title: t('toast.conflictTitle'),
            message: t('toast.conflictMessage'),
          });
          await reloadLatest();
          return false;
        }
        if (!options?.silent) {
          showError(error);
        }
        return false;
      } finally {
        setBusy(false);
      }
    },
    [form, onPostChange, post.id, post.updatedAt, refresh, reloadLatest, showError, showToast, t],
  );

  const saveIfDirty = useCallback(async (): Promise<boolean> => {
    if (!form.dirty) return true;
    return save();
  }, [form.dirty, save]);

  const runLifecycle = useCallback(
    async (
      action: () => Promise<NewsPostAdminDto>,
      successKey: 'toast.published' | 'toast.unpublished' | 'toast.archived',
    ) => {
      setBusy(true);
      try {
        const updated = await action();
        onPostChange(updated);
        form.reset(postToFormValues(updated));
        showToast({ tone: 'success', title: t(successKey), message: '' });
        refresh();
      } catch (error) {
        showError(error);
      } finally {
        setBusy(false);
      }
    },
    [form, onPostChange, refresh, showError, showToast, t],
  );

  const requestPublish = useCallback(() => {
    if (blockIfDirty()) return;
    const validationError = validateNewsPostForm(form.values, {
      mode: 'publish',
      hasCover: Boolean(post.coverMediaId),
    });
    if (validationError) {
      showToast({
        tone: 'warning',
        title: t('toast.validationTitle'),
        message: t(`validation.${validationError}`),
      });
      return;
    }
    setPublishOpen(true);
  }, [blockIfDirty, form.values, post.coverMediaId, showToast, t]);

  const confirmPublish = useCallback(async () => {
    setPublishOpen(false);
    await runLifecycle(() => publishNewsPost(post.id), 'toast.published');
  }, [post.id, runLifecycle]);

  const requestUnpublish = useCallback(() => {
    if (blockIfDirty()) return;
    setUnpublishOpen(true);
  }, [blockIfDirty]);

  const confirmUnpublish = useCallback(async () => {
    setUnpublishOpen(false);
    await runLifecycle(() => unpublishNewsPost(post.id), 'toast.unpublished');
  }, [post.id, runLifecycle]);

  const requestArchive = useCallback(() => {
    if (blockIfDirty()) return;
    setArchiveOpen(true);
  }, [blockIfDirty]);

  const confirmArchive = useCallback(async () => {
    setArchiveOpen(false);
    await runLifecycle(() => archiveNewsPost(post.id), 'toast.archived');
  }, [post.id, runLifecycle]);

  const confirmDelete = useCallback(async () => {
    setDeleteOpen(false);
    setBusy(true);
    try {
      await deleteNewsPost(post.id);
      showToast({ tone: 'success', title: t('toast.deleted'), message: '' });
      onDeleted?.();
    } catch (error) {
      showError(error);
    } finally {
      setBusy(false);
    }
  }, [onDeleted, post.id, showError, showToast, t]);

  const uploadCover = useCallback(
    async (file: File) => {
      setBusy(true);
      try {
        await uploadNewsMedia(post.id, 'cover', file);
        await mergePostMedia(form.dirty);
        showToast({ tone: 'success', title: t('toast.mediaUploaded'), message: '' });
      } catch (error) {
        showError(error);
      } finally {
        setBusy(false);
      }
    },
    [form.dirty, mergePostMedia, post.id, showError, showToast, t],
  );

  const uploadInline = useCallback(
    async (file: File, kind: 'inline_image' | 'inline_video') => {
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
        const updated = await fetchNewsPost(post.id);
        onPostChange(updated);
        showToast({ tone: 'success', title: t('toast.mediaUploaded'), message: '' });
        refresh();
      } catch (error) {
        showError(error);
      } finally {
        setBusy(false);
      }
    },
    [form, locale, onPostChange, post.id, refresh, showError, showToast, t],
  );

  const updateMediaAlt = useCallback(
    async (mediaId: string, altText: Partial<Record<NewsLocale, string>>) => {
      setBusy(true);
      try {
        await updateNewsMediaAlt(mediaId, altText);
        const updated = await fetchNewsPost(post.id);
        onPostChange(updated);
      } catch (error) {
        showError(error);
      } finally {
        setBusy(false);
      }
    },
    [onPostChange, post.id, showError],
  );

  const removeMedia = useCallback(
    async (mediaId: string, referencedInBody: boolean) => {
      if (referencedInBody) {
        showToast({
          tone: 'warning',
          title: t('toast.mediaInUseTitle'),
          message: t('toast.mediaInUseMessage'),
        });
        return;
      }
      setBusy(true);
      try {
        await deleteNewsMedia(mediaId);
        await mergePostMedia(form.dirty);
        showToast({ tone: 'success', title: t('toast.mediaDeleted'), message: '' });
      } catch (error) {
        showError(error);
      } finally {
        setBusy(false);
      }
    },
    [form.dirty, mergePostMedia, showError, showToast, t],
  );

  return {
    busy,
    save,
    saveIfDirty,
    uploadCover,
    uploadInline,
    removeMedia,
    updateMediaAlt,
    requestPublish,
    confirmPublish,
    requestUnpublish,
    confirmUnpublish,
    requestArchive,
    confirmArchive,
    confirmDelete,
    publishOpen,
    setPublishOpen,
    unpublishOpen,
    setUnpublishOpen,
    archiveOpen,
    setArchiveOpen,
    deleteOpen,
    setDeleteOpen,
  };
}
