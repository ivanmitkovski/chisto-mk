'use client';

import { useState } from 'react';
import { Button } from '@/components/ui';
import { postSiteHistoryNote } from '@/lib/api/site-history';
import { ApiError } from '@/lib/api';
import styles from '@/app/dashboard/sites/[id]/site-detail.module.css';

type SiteTimelineNoteFormProps = {
  siteId: string;
  onPosted?: () => void;
};

export function SiteTimelineNoteForm({ siteId, onPosted }: SiteTimelineNoteFormProps) {
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
      setError(e instanceof ApiError ? e.message : 'Failed to post note');
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className={styles.sectionCard}>
      <span className={styles.sectionLabel}>Timeline note</span>
      <textarea
        rows={3}
        value={note}
        onChange={(e) => setNote(e.target.value)}
        placeholder="Visible to users on the site history tab…"
        disabled={busy}
        style={{ width: '100%', marginBottom: 'var(--space-3)' }}
      />
      {error ? <p style={{ color: 'var(--color-danger, #b91c1c)' }}>{error}</p> : null}
      <Button type="button" disabled={busy || !note.trim()} onClick={() => void submit()}>
        {busy ? 'Posting…' : 'Post note'}
      </Button>
    </section>
  );
}
