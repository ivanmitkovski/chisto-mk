'use client';

import { useCallback, useRef, useState } from 'react';
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
import { fromDatetimeLocalValue, toDatetimeLocalValue } from '@/lib/datetime/datetime-local';
import { ApiError } from '@/lib/api';
import type { NewsLocale } from '../news-api-types';
import { newsApiErrorMessage } from '../lib/news-api-messages';
import {
  newsMediaValidationMessage,
  validateNewsMediaFile,
} from '../lib/news-media-validation';
import { validateNewsPostForm } from '../lib/news-post-policy';
import { prepareNewsSavePayload } from '../lib/news-save-payload';
import type { NewsBodyBlock, NewsMediaDto, NewsPostAdminDto } from '../news-api-types';
import type { NewsFormLocale, NewsPostFormValues } from '../types';
import { postToFormValues } from '../types';

type UploadKind = 'cover' | 'inline_image' | 'inline_video';

type BlockUploadPreview = {
  blockIndex: number;
  url: string;
};

function mergeUploadedMedia(post: NewsPostAdminDto, uploaded: NewsMediaDto): NewsPostAdminDto {
  const media = post.media.some((item) => item.id === uploaded.id)
    ? post.media.map((item) => (item.id === uploaded.id ? uploaded : item))
    : [...post.media, uploaded];
  return { ...post, media };
}

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
  isDirty: () => boolean;
  onPostChange: (post: NewsPostAdminDto) => void;
  onDeleted?: () => void;
  flushBeforeAction?: () => Promise<void>;
};

export function useNewsPostMutations({
  post,
  form,
  locale,
  isDirty,
  onPostChange,
  onDeleted,
  flushBeforeAction,
}: UseNewsPostMutationsOptions) {
  const t = useTranslations('news');
  const { showToast } = useToast();
  const { refresh } = useWorkspaceRefresh();
  const [saving, setSaving] = useState(false);
  const [lifecycleBusy, setLifecycleBusy] = useState(false);
  const [uploadingKind, setUploadingKind] = useState<UploadKind | null>(null);
  const [uploadingGallerySlot, setUploadingGallerySlot] = useState<{
    blockIndex: number;
    itemIndex: number;
  } | null>(null);
  const saveInFlightRef = useRef(false);
  const [uploadValidationErrors, setUploadValidationErrors] = useState<
    Partial<Record<UploadKind, string>>
  >({});
  const [blockUploadPreview, setBlockUploadPreview] = useState<BlockUploadPreview | null>(null);
  const [publishOpen, setPublishOpen] = useState(false);
  const [unpublishOpen, setUnpublishOpen] = useState(false);
  const [archiveOpen, setArchiveOpen] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);

  const formValuesRef = useRef(form.values);
  formValuesRef.current = form.values;

  const clearBlockUploadPreview = useCallback(() => {
    setBlockUploadPreview((current) => {
      if (current) URL.revokeObjectURL(current.url);
      return null;
    });
  }, []);

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
    if (!isDirty()) return false;
    showToast({
      tone: 'warning',
      title: t('toast.unsavedTitle'),
      message: t('toast.unsavedMessage'),
    });
    return true;
  }, [isDirty, showToast, t]);

  const save = useCallback(
    async (options?: { silent?: boolean }): Promise<boolean> => {
      if (saveInFlightRef.current) return false;

      const validationError = validateNewsPostForm(form.values, {
        mode: 'save',
        hasCover: Boolean(post.coverMediaId),
      });
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

      saveInFlightRef.current = true;
      setSaving(true);
      try {
        await flushBeforeAction?.();

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

        const payload = prepareNewsSavePayload(formValuesRef.current);
        const nextScheduledAt = fromDatetimeLocalValue(payload.scheduledAt);
        const scheduledChanged =
          payload.scheduledAt.trim() !== toDatetimeLocalValue(post.scheduledAt);
        const updated = await updateNewsPost(post.id, {
          slug: payload.slug,
          category: payload.category,
          translations: payload.translations,
          featured: payload.featured,
          ...(scheduledChanged ? { scheduledAt: nextScheduledAt } : {}),
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
        saveInFlightRef.current = false;
        setSaving(false);
      }
    },
    [flushBeforeAction, form, onPostChange, post.id, post.updatedAt, refresh, reloadLatest, showError, showToast, t],
  );

  const saveIfDirty = useCallback(async (): Promise<boolean> => {
    if (!isDirty()) return true;
    return save();
  }, [isDirty, save]);

  const runLifecycle = useCallback(
    async (
      action: () => Promise<NewsPostAdminDto>,
      successKey: 'toast.published' | 'toast.unpublished' | 'toast.archived',
    ) => {
      setLifecycleBusy(true);
      try {
        const updated = await action();
        onPostChange(updated);
        form.reset(postToFormValues(updated));
        showToast({ tone: 'success', title: t(successKey), message: '' });
        refresh();
      } catch (error) {
        showError(error);
      } finally {
        setLifecycleBusy(false);
      }
    },
    [form, onPostChange, refresh, showError, showToast, t],
  );

  const requestPublish = useCallback(() => {
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
  }, [form.values, post.coverMediaId, showToast, t]);

  const confirmPublish = useCallback(async () => {
    setPublishOpen(false);
    try {
      await flushBeforeAction?.();
    } catch (error) {
      showError(error);
      return;
    }
    await runLifecycle(() => publishNewsPost(post.id), 'toast.published');
  }, [flushBeforeAction, post.id, runLifecycle, showError]);

  const saveAndPublish = useCallback(async () => {
    setPublishOpen(false);
    setLifecycleBusy(true);
    try {
      try {
        await flushBeforeAction?.();
      } catch (error) {
        showError(error);
        return;
      }
      const saved = await save({ silent: true });
      if (!saved) {
        showToast({
          tone: 'warning',
          title: t('toast.validationTitle'),
          message: t('toast.saveBeforePublish'),
        });
        return;
      }
      await runLifecycle(() => publishNewsPost(post.id), 'toast.published');
    } finally {
      setLifecycleBusy(false);
    }
  }, [flushBeforeAction, post.id, runLifecycle, save, showError, showToast, t]);

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
    setLifecycleBusy(true);
    try {
      await deleteNewsPost(post.id);
      showToast({ tone: 'success', title: t('toast.deleted'), message: '' });
      onDeleted?.();
    } catch (error) {
      showError(error);
    } finally {
      setLifecycleBusy(false);
    }
  }, [onDeleted, post.id, showError, showToast, t]);

  const uploadMedia = useCallback(
    async (file: File, kind: UploadKind) => {
      const validation = await validateNewsMediaFile(file, kind);
      if (!validation.ok) {
        const message = newsMediaValidationMessage(t, validation);
        setUploadValidationErrors((prev) => ({ ...prev, [kind]: message }));
        showToast({
          tone: 'warning',
          title: t('toast.validationTitle'),
          message,
        });
        return;
      }
      setUploadValidationErrors((prev) => {
        const next = { ...prev };
        delete next[kind];
        return next;
      });

      setUploadingKind(kind);
      const localPreviewUrl = kind === 'inline_video' ? URL.createObjectURL(file) : null;
      const previewBlockIndex = kind === 'cover' ? -1 : formValuesRef.current.translations[locale].body.length;
      if (localPreviewUrl && previewBlockIndex >= 0) {
        setBlockUploadPreview({ blockIndex: previewBlockIndex, url: localPreviewUrl });
      }
      try {
        const result = await uploadNewsMedia(post.id, kind, file);
        if (kind === 'cover') {
          await mergePostMedia(isDirty());
        } else {
          const mediaId = result.id;
          const loc = formValuesRef.current.translations[locale];
          const block: NewsBodyBlock =
            kind === 'inline_video' ? { type: 'video', mediaId } : { type: 'image', mediaId };
          form.onChange('translations', {
            ...formValuesRef.current.translations,
            [locale]: { ...loc, body: [...loc.body, block] },
          });
          onPostChange(mergeUploadedMedia(post, result));
          const updated = await fetchNewsPost(post.id);
          onPostChange(updated);
          refresh();
        }
        showToast({ tone: 'success', title: t('toast.mediaUploaded'), message: '' });
      } catch (error) {
        showError(error);
      } finally {
        setUploadingKind(null);
        if (localPreviewUrl) clearBlockUploadPreview();
      }
    },
    [clearBlockUploadPreview, form, isDirty, locale, mergePostMedia, onPostChange, post, refresh, showError, showToast, t],
  );

  const uploadCover = useCallback(
    async (file: File) => uploadMedia(file, 'cover'),
    [uploadMedia],
  );

  const uploadInline = useCallback(
    async (file: File, kind: 'inline_image' | 'inline_video') => uploadMedia(file, kind),
    [uploadMedia],
  );

  const uploadForBlock = useCallback(
    async (blockIndex: number, file: File, kind: 'inline_image' | 'inline_video') => {
      const validation = await validateNewsMediaFile(file, kind);
      if (!validation.ok) {
        const message = newsMediaValidationMessage(t, validation);
        setUploadValidationErrors((prev) => ({ ...prev, [kind]: message }));
        showToast({
          tone: 'warning',
          title: t('toast.validationTitle'),
          message,
        });
        return;
      }
      setUploadValidationErrors((prev) => {
        const next = { ...prev };
        delete next[kind];
        return next;
      });

      setUploadingKind(kind);
      const localPreviewUrl = kind === 'inline_video' ? URL.createObjectURL(file) : null;
      if (localPreviewUrl) {
        setBlockUploadPreview({ blockIndex, url: localPreviewUrl });
      }
      try {
        const result = await uploadNewsMedia(post.id, kind, file);
        const loc = formValuesRef.current.translations[locale];
        const body = [...loc.body];
        const block = body[blockIndex];
        if (!block || (block.type !== 'image' && block.type !== 'video')) return;
        body[blockIndex] = { ...block, mediaId: result.id };
        form.onChange('translations', {
          ...formValuesRef.current.translations,
          [locale]: { ...loc, body },
        });
        onPostChange(mergeUploadedMedia(post, result));
        const updated = await fetchNewsPost(post.id);
        onPostChange(updated);
        refresh();
        showToast({ tone: 'success', title: t('toast.mediaUploaded'), message: '' });
      } catch (error) {
        showError(error);
      } finally {
        setUploadingKind(null);
        if (localPreviewUrl) clearBlockUploadPreview();
      }
    },
    [clearBlockUploadPreview, form, locale, onPostChange, post, refresh, showError, showToast, t],
  );

  const uploadForGallerySlot = useCallback(
    async (blockIndex: number, itemIndex: number, file: File) => {
      const validation = await validateNewsMediaFile(file, 'inline_image');
      if (!validation.ok) {
        const message = newsMediaValidationMessage(t, validation);
        setUploadValidationErrors((prev) => ({ ...prev, inline_image: message }));
        showToast({
          tone: 'warning',
          title: t('toast.validationTitle'),
          message,
        });
        return;
      }
      setUploadValidationErrors((prev) => {
        const next = { ...prev };
        delete next.inline_image;
        return next;
      });

      setUploadingKind('inline_image');
      setUploadingGallerySlot({ blockIndex, itemIndex });
      try {
        const result = (await uploadNewsMedia(post.id, 'inline_image', file)) as { id: string };
        const loc = formValuesRef.current.translations[locale];
        const body = [...loc.body];
        const block = body[blockIndex];
        if (!block || block.type !== 'gallery') return;
        const items = [...block.items];
        if (itemIndex < 0 || itemIndex >= items.length) return;
        items[itemIndex] = { ...items[itemIndex], mediaId: result.id };
        body[blockIndex] = { ...block, items };
        form.onChange('translations', {
          ...formValuesRef.current.translations,
          [locale]: { ...loc, body },
        });
        const updated = await fetchNewsPost(post.id);
        onPostChange(updated);
        refresh();
        showToast({ tone: 'success', title: t('toast.mediaUploaded'), message: '' });
      } catch (error) {
        showError(error);
      } finally {
        setUploadingKind(null);
        setUploadingGallerySlot(null);
      }
    },
    [form, locale, onPostChange, post.id, refresh, showError, showToast, t],
  );

  const uploadInlineAt = useCallback(
    async (file: File, kind: 'inline_image' | 'inline_video', insertIndex: number) => {
      const validation = await validateNewsMediaFile(file, kind);
      if (!validation.ok) {
        const message = newsMediaValidationMessage(t, validation);
        setUploadValidationErrors((prev) => ({ ...prev, [kind]: message }));
        showToast({
          tone: 'warning',
          title: t('toast.validationTitle'),
          message,
        });
        return;
      }
      setUploadValidationErrors((prev) => {
        const next = { ...prev };
        delete next[kind];
        return next;
      });

      setUploadingKind(kind);
      const localPreviewUrl = kind === 'inline_video' ? URL.createObjectURL(file) : null;
      if (localPreviewUrl) {
        setBlockUploadPreview({ blockIndex: insertIndex, url: localPreviewUrl });
      }
      try {
        const result = await uploadNewsMedia(post.id, kind, file);
        const mediaId = result.id;
        const loc = formValuesRef.current.translations[locale];
        const block: NewsBodyBlock =
          kind === 'inline_video' ? { type: 'video', mediaId } : { type: 'image', mediaId };
        const body = [...loc.body];
        body.splice(insertIndex, 0, block);
        form.onChange('translations', {
          ...formValuesRef.current.translations,
          [locale]: { ...loc, body },
        });
        onPostChange(mergeUploadedMedia(post, result));
        const updated = await fetchNewsPost(post.id);
        onPostChange(updated);
        refresh();
        showToast({ tone: 'success', title: t('toast.mediaUploaded'), message: '' });
      } catch (error) {
        showError(error);
      } finally {
        setUploadingKind(null);
        if (localPreviewUrl) clearBlockUploadPreview();
      }
    },
    [clearBlockUploadPreview, form, locale, onPostChange, post, refresh, showError, showToast, t],
  );

  const updateMediaAlt = useCallback(
    async (mediaId: string, altText: Partial<Record<NewsLocale, string>>) => {
      await updateNewsMediaAlt(mediaId, altText);
    },
    [],
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
      setLifecycleBusy(true);
      try {
        await deleteNewsMedia(mediaId);
        await mergePostMedia(isDirty());
        showToast({ tone: 'success', title: t('toast.mediaDeleted'), message: '' });
      } catch (error) {
        showError(error);
      } finally {
        setLifecycleBusy(false);
      }
    },
    [isDirty, mergePostMedia, showError, showToast, t],
  );

  const busy = saving || lifecycleBusy || uploadingKind !== null;

  return {
    busy,
    saving,
    lifecycleBusy,
    uploadingKind,
    uploadingGallerySlot,
    blockUploadPreview,
    uploadValidationErrors,
    save,
    saveIfDirty,
    uploadCover,
    uploadInline,
    uploadInlineAt,
    uploadForBlock,
    uploadForGallerySlot,
    removeMedia,
    updateMediaAlt,
    requestPublish,
    confirmPublish,
    saveAndPublish,
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
