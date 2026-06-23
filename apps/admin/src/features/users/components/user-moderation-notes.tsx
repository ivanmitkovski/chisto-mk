'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Card, Input, useToast } from '@/components/ui';
import { useReadOnlyUnless } from '@/lib/auth/rbac';
import { adminBrowserFetch } from '@/lib/api';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import styles from './user-moderation-notes.module.css';

type ModerationNote = {
  id: string;
  body: string;
  createdAt: string;
  authorEmail: string;
  authorName: string;
};

type UserModerationNotesProps = {
  userId: string;
  initialNotes: ModerationNote[];
};

export function UserModerationNotes({ userId, initialNotes }: UserModerationNotesProps) {
  const t = useTranslations('users');
  const tCommon = useTranslations('common');
  const locale = useAdminBcp47Locale();
  const readOnly = useReadOnlyUnless('users:write');
  const { showToast } = useToast();
  const [notes, setNotes] = useState(initialNotes);
  const [body, setBody] = useState('');
  const [busy, setBusy] = useState(false);

  async function addNote() {
    const trimmed = body.trim();
    if (!trimmed) return;
    setBusy(true);
    try {
      const created = await adminBrowserFetch<ModerationNote>(
        `/admin/users/${userId}/moderation-notes`,
        { method: 'POST', body: { body: trimmed } },
      );
      setNotes((current) => [created, ...current]);
      setBody('');
      showToast({ tone: 'success', title: tCommon('saved'), message: t('detail.notes.added') });
    } catch (error) {
      showToast({
        tone: 'warning',
        title: tCommon('error'),
        message: error instanceof Error ? error.message : t('detail.notes.addFailed'),
      });
    } finally {
      setBusy(false);
    }
  }

  return (
    <Card padding="md" className={styles.root}>
      <h3 className={styles.title}>{t('detail.notes.title')}</h3>
      {!readOnly ? (
        <div className={styles.form}>
          <Input
            label={t('detail.notes.addLabel')}
            value={body}
            onChange={(e) => setBody(e.target.value)}
            disabled={busy}
          />
          <Button type="button" onClick={() => void addNote()} disabled={busy || !body.trim()}>
            {t('detail.notes.add')}
          </Button>
        </div>
      ) : null}
      <ul className={styles.list}>
        {notes.map((note) => (
          <li key={note.id}>
            <p className={styles.body}>{note.body}</p>
            <p className={styles.meta}>
              {note.authorName || note.authorEmail} · {formatAdminDateTime(note.createdAt, locale)}
            </p>
          </li>
        ))}
      </ul>
      {notes.length === 0 ? <p className={styles.empty}>{t('detail.notes.empty')}</p> : null}
    </Card>
  );
}
