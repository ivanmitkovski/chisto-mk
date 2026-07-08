'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, ConfirmDialog, Spinner, useToast } from '@/components/ui';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import {
  clearNewsRevisions,
  listNewsRevisions,
  restoreNewsRevision,
  type NewsRevisionDto,
} from '../data/news-adapter-client';
import { summarizeLocaleContentDiff } from '../lib/news-revision-diff';
import { newsApiErrorMessage } from '../lib/news-api-messages';
import type { NewsMediaDto, NewsPostAdminDto } from '../news-api-types';
import { NewsPreviewBlocks, resolvePreviewBlocks } from './news-preview-blocks';
import styles from './news-revision-panel.module.css';

function NewsRevisionBodyPreview({
  body,
  media,
  locale,
}: {
  body: NewsPostAdminDto['translations']['en']['body'];
  media: NewsMediaDto[];
  locale: 'en' | 'mk' | 'sq';
}) {
  if (!body.length) return null;
  const resolved = resolvePreviewBlocks(body, media, locale);
  return (
    <div className={styles.previewBody}>
      <NewsPreviewBlocks body={resolved} />
    </div>
  );
}

const VISIBLE_COLLAPSED = 5;
const REVISIONS_MAX_STORED = 10;

type NewsRevisionPanelProps = {
  postId: string;
  media: NewsMediaDto[];
  readOnly: boolean;
  hasUnsavedChanges?: boolean;
  activeLocale?: 'en' | 'mk' | 'sq';
  currentValues?: import('../types').NewsPostFormValues | undefined;
  embedded?: boolean;
  onBeforeRestore?: () => Promise<void>;
  onRestored: (post: NewsPostAdminDto) => void;
};

export function NewsRevisionPanel({
  postId,
  media,
  readOnly,
  hasUnsavedChanges = false,
  activeLocale = 'en',
  currentValues,
  embedded = false,
  onBeforeRestore,
  onRestored,
}: NewsRevisionPanelProps) {
  const t = useTranslations('news');
  const locale = useAdminBcp47Locale();
  const { showToast } = useToast();
  const [revisions, setRevisions] = useState<NewsRevisionDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [expanded, setExpanded] = useState(false);
  const [restoreId, setRestoreId] = useState<string | null>(null);
  const [dirtyRestoreId, setDirtyRestoreId] = useState<string | null>(null);
  const [clearOpen, setClearOpen] = useState(false);
  const [previewId, setPreviewId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const rows = await listNewsRevisions(postId);
      setRevisions(rows);
      if (rows.length <= VISIBLE_COLLAPSED) {
        setExpanded(false);
      }
    } catch (error) {
      showToast({
        tone: 'error',
        title: t('toast.error'),
        message: newsApiErrorMessage(error, t, t('toast.error')),
      });
    } finally {
      setLoading(false);
    }
  }, [postId, showToast, t]);

  useEffect(() => {
    void load();
  }, [load]);

  const visibleRevisions = useMemo(() => {
    if (expanded || revisions.length <= VISIBLE_COLLAPSED) return revisions;
    return revisions.slice(0, VISIBLE_COLLAPSED);
  }, [expanded, revisions]);

  const hiddenCount = Math.max(0, revisions.length - VISIBLE_COLLAPSED);

  async function confirmRestore() {
    if (!restoreId) return;
    setRestoreId(null);
    setBusy(true);
    try {
      await onBeforeRestore?.();
      const updated = await restoreNewsRevision(postId, restoreId);
      onRestored(updated);
      showToast({ tone: 'success', title: t('revisions.restored'), message: '' });
      await load();
    } catch (error) {
      showToast({
        tone: 'error',
        title: t('toast.error'),
        message: newsApiErrorMessage(error, t, t('toast.error')),
      });
    } finally {
      setBusy(false);
    }
  }

  async function confirmClear() {
    setClearOpen(false);
    setPreviewId(null);
    setBusy(true);
    try {
      await clearNewsRevisions(postId);
      setRevisions([]);
      setExpanded(false);
      showToast({ tone: 'success', title: t('revisions.cleared'), message: '' });
    } catch (error) {
      showToast({
        tone: 'error',
        title: t('toast.error'),
        message: newsApiErrorMessage(error, t, t('toast.error')),
      });
    } finally {
      setBusy(false);
    }
  }

  const preview = previewId ? revisions.find((r) => r.id === previewId) : null;

  return (
    <section className={embedded ? styles.embedded : styles.root} aria-label={t('revisions.label')}>
      <div className={styles.header}>
        <div>
          {!embedded ? <h3 className={styles.heading}>{t('revisions.label')}</h3> : null}
          {!loading && revisions.length > 0 ? (
            <p className={styles.meta}>{t('revisions.retentionHint', { max: REVISIONS_MAX_STORED })}</p>
          ) : null}
        </div>
        {!readOnly && !loading && revisions.length > 0 ? (
          <Button
            type="button"
            variant="ghost"
            size="sm"
            disabled={busy}
            onClick={() => setClearOpen(true)}
          >
            {t('revisions.clear')}
          </Button>
        ) : null}
      </div>

      {loading ? (
        <div className={styles.loading}>
          <Spinner size="sm" aria-label={t('revisions.loading')} />
        </div>
      ) : revisions.length === 0 ? (
        <p className={styles.muted}>{t('revisions.empty')}</p>
      ) : (
        <>
          <div className={expanded ? styles.timelineScroll : undefined}>
            <ol className={styles.timeline}>
              {visibleRevisions.map((rev) => (
                <li key={rev.id} className={styles.entry}>
                  <time className={styles.time} dateTime={rev.createdAt}>
                    {formatAdminDateTime(rev.createdAt, locale)}
                  </time>
                  <span className={styles.slug}>{rev.snapshot.slug}</span>
                  <div className={styles.actions}>
                    <Button type="button" variant="ghost" size="sm" onClick={() => setPreviewId(rev.id)}>
                      {t('revisions.preview')}
                    </Button>
                    {!readOnly ? (
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        disabled={busy}
                        onClick={() => {
                          if (hasUnsavedChanges) {
                            setDirtyRestoreId(rev.id);
                          } else {
                            setRestoreId(rev.id);
                          }
                        }}
                      >
                        {t('revisions.restore')}
                      </Button>
                    ) : null}
                  </div>
                </li>
              ))}
            </ol>
          </div>
          {hiddenCount > 0 && !expanded ? (
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className={styles.expandBtn}
              onClick={() => setExpanded(true)}
            >
              {t('revisions.showAll', { count: revisions.length })}
            </Button>
          ) : null}
          {expanded && revisions.length > VISIBLE_COLLAPSED ? (
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className={styles.expandBtn}
              onClick={() => setExpanded(false)}
            >
              {t('revisions.showLess')}
            </Button>
          ) : null}
        </>
      )}

      {preview ? (
        <div className={styles.previewBox} role="region" aria-label={t('revisions.preview')}>
          {currentValues ? (
            <div className={styles.diffChips} role="status">
              {(() => {
                const before = preview.snapshot.translations[activeLocale];
                const after = currentValues.translations[activeLocale];
                const diff = summarizeLocaleContentDiff(before, after);
                return (
                  <>
                    {diff.titleChanged ? <span className={styles.diffChip}>{t('revisions.diffTitle')}</span> : null}
                    {diff.excerptChanged ? <span className={styles.diffChip}>{t('revisions.diffExcerpt')}</span> : null}
                    {diff.blockDelta !== 0 ? (
                      <span className={styles.diffChip}>
                        {t('revisions.diffBlocks', { delta: diff.blockDelta > 0 ? `+${diff.blockDelta}` : String(diff.blockDelta) })}
                      </span>
                    ) : null}
                    {diff.mediaDelta !== 0 ? (
                      <span className={styles.diffChip}>
                        {t('revisions.diffMedia', { delta: diff.mediaDelta > 0 ? `+${diff.mediaDelta}` : String(diff.mediaDelta) })}
                      </span>
                    ) : null}
                    {!diff.titleChanged && !diff.excerptChanged && diff.blockDelta === 0 && diff.mediaDelta === 0 ? (
                      <span className={styles.diffChipMuted}>{t('revisions.diffNone')}</span>
                    ) : null}
                  </>
                );
              })()}
            </div>
          ) : null}
          <p className={styles.previewTitle}>
            {preview.snapshot.translations[activeLocale]?.title ??
              preview.snapshot.translations.en.title}
          </p>
          <p className={styles.previewExcerpt}>
            {preview.snapshot.translations[activeLocale]?.excerpt ??
              preview.snapshot.translations.en.excerpt}
          </p>
          <NewsRevisionBodyPreview
            body={
              preview.snapshot.translations[activeLocale]?.body ??
              preview.snapshot.translations.en.body
            }
            media={media}
            locale={activeLocale}
          />
          <Button type="button" variant="ghost" size="sm" onClick={() => setPreviewId(null)}>
            {t('actions.back')}
          </Button>
        </div>
      ) : null}

      <ConfirmDialog
        open={clearOpen}
        title={t('revisions.clearTitle')}
        description={t('revisions.clearBody')}
        confirmLabel={t('revisions.clear')}
        tone="danger"
        onConfirm={() => void confirmClear()}
        onClose={() => setClearOpen(false)}
      />
      <ConfirmDialog
        open={dirtyRestoreId != null}
        title={t('confirm.unsavedTitle')}
        description={t('confirm.unsavedRestoreBody')}
        confirmLabel={t('revisions.restore')}
        onConfirm={() => {
          if (dirtyRestoreId) {
            setRestoreId(dirtyRestoreId);
            setDirtyRestoreId(null);
          }
        }}
        onClose={() => setDirtyRestoreId(null)}
      />
      <ConfirmDialog
        open={restoreId != null}
        title={t('revisions.restoreTitle')}
        description={t('revisions.restoreBody')}
        confirmLabel={t('revisions.restore')}
        onConfirm={() => void confirmRestore()}
        onClose={() => setRestoreId(null)}
      />
    </section>
  );
}
