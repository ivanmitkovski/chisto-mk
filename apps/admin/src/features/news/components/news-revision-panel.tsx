'use client';

import { useCallback, useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, ConfirmDialog, useToast } from '@/components/ui';
import {
  listNewsRevisions,
  restoreNewsRevision,
  type NewsRevisionDto,
} from '../data/news-adapter-client';
import { newsApiErrorMessage } from '../lib/news-api-messages';
import type { NewsPostAdminDto } from '../news-api-types';
import styles from './news-revision-panel.module.css';

type NewsRevisionPanelProps = {
  postId: string;
  readOnly: boolean;
  onRestored: (post: NewsPostAdminDto) => void;
};

export function NewsRevisionPanel({ postId, readOnly, onRestored }: NewsRevisionPanelProps) {
  const t = useTranslations('news');
  const { showToast } = useToast();
  const [revisions, setRevisions] = useState<NewsRevisionDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [restoreId, setRestoreId] = useState<string | null>(null);
  const [previewId, setPreviewId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const rows = await listNewsRevisions(postId);
      setRevisions(rows);
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

  async function confirmRestore() {
    if (!restoreId) return;
    setRestoreId(null);
    setBusy(true);
    try {
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

  const preview = previewId ? revisions.find((r) => r.id === previewId) : null;

  return (
    <section className={styles.root} aria-label={t('revisions.label')}>
      <h3 className={styles.heading}>{t('revisions.label')}</h3>
      {loading ? (
        <p className={styles.muted}>…</p>
      ) : revisions.length === 0 ? (
        <p className={styles.muted}>{t('revisions.empty')}</p>
      ) : (
        <ol className={styles.timeline}>
          {revisions.map((rev) => (
            <li key={rev.id} className={styles.entry}>
              <time className={styles.time} dateTime={rev.createdAt}>
                {new Date(rev.createdAt).toLocaleString()}
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
                    onClick={() => setRestoreId(rev.id)}
                  >
                    {t('revisions.restore')}
                  </Button>
                ) : null}
              </div>
            </li>
          ))}
        </ol>
      )}

      {preview ? (
        <div className={styles.previewBox} role="region" aria-label={t('revisions.preview')}>
          <p className={styles.previewTitle}>{preview.snapshot.translations.en.title}</p>
          <p className={styles.previewExcerpt}>{preview.snapshot.translations.en.excerpt}</p>
          <Button type="button" variant="ghost" size="sm" onClick={() => setPreviewId(null)}>
            {t('actions.back')}
          </Button>
        </div>
      ) : null}

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
