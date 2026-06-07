'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui';
import { Can } from '@/lib/auth/rbac';
import { postSiteHistoryNote } from '@/lib/api';
import { ApiError } from '@/lib/api';
import styles from './site-detail.module.css';

type SiteTimelineNoteFormProps = {
  siteId: string;
  onPosted?: () => void;
};

export function SiteTimelineNoteForm({ siteId, onPosted }: SiteTimelineNoteFormProps) {
  const t = useTranslations('sites');
  const [note, setNote] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit() {
    const trimmed = note.trim();
    if (!trimmed) return;
    setBusy(true);
    setError(null);
    try {
      await postSiteHistoryNote(siteId, { note: trimmed });
      setNote('');
      onPosted?.();
    } catch (e) {
      setError(e instanceof ApiError ? e.message : t('detail.postNoteFailed'));
    } finally {
      setBusy(false);
    }
  }

  return (
    <Can permission="sites:write">
      <section className={styles.sectionCard}>
        <span className={styles.sectionLabel}>{t('detail.timelineNote')}</span>
        <textarea
          rows={3}
          value={note}
          onChange={(e) => setNote(e.target.value)}
          placeholder={t('detail.timelineNotePlaceholder')}
          disabled={busy}
          className={styles.timelineNoteTextarea}
        />
        {error ? <p className={styles.timelineNoteError}>{error}</p> : null}
        <Button type="button" disabled={busy || !note.trim()} onClick={() => void submit()}>
          {busy ? t('detail.posting') : t('detail.postNote')}
        </Button>
      </section>
    </Can>
  );
}
