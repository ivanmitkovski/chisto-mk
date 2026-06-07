'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, ConfirmDialog, Icon } from '@/components/ui';
import type { CleanupEventDetail } from '@/features/events/data/events-adapter';
import styles from './event-detail.module.css';

type EventDetailLifecyclePanelProps = {
  event: CleanupEventDetail;
  canWrite: boolean;
  saving: boolean;
  isDirty: boolean;
  onStartInProgress: () => void;
  onMarkComplete: () => void;
  onCancel: () => void;
};

export function EventDetailLifecyclePanel({
  event,
  canWrite,
  saving,
  isDirty,
  onStartInProgress,
  onMarkComplete,
  onCancel,
}: EventDetailLifecyclePanelProps) {
  const tDetail = useTranslations('events.detail');
  const [cancelOpen, setCancelOpen] = useState(false);
  const lifecycle = event.lifecycleStatus;
  const disabled = !canWrite || saving || isDirty;

  const canStart =
    canWrite && lifecycle === 'UPCOMING' && event.status === 'APPROVED' && !event.completedAt;
  const canComplete =
    canWrite &&
    lifecycle !== 'COMPLETED' &&
    lifecycle !== 'CANCELLED' &&
    event.status === 'APPROVED';
  const canCancel =
    canWrite && lifecycle !== 'CANCELLED' && lifecycle !== 'COMPLETED';

  return (
    <section className={styles.sectionCard} aria-label={tDetail('lifecyclePanelAria')}>
      <span className={styles.sectionLabel}>{tDetail('lifecycle')}</span>
      <p className={styles.fieldHint}>{tDetail('currentLifecycle', { status: lifecycle })}</p>
      {isDirty ? (
        <p className={styles.fieldError} role="status">
          {tDetail('unsavedChangesActionBlocked')}
        </p>
      ) : null}
      <div className={styles.lifecycleActions}>
        {canStart ? (
          <Button variant="outline" size="sm" disabled={disabled} onClick={onStartInProgress}>
            {tDetail('startInProgress')}
          </Button>
        ) : null}
        {canComplete ? (
          <Button variant="outline" size="sm" disabled={disabled} onClick={onMarkComplete}>
            <Icon name="check" size={14} />
            {tDetail('markCompleted')}
          </Button>
        ) : null}
        {canCancel ? (
          <Button variant="outline" size="sm" disabled={disabled} onClick={() => setCancelOpen(true)}>
            {tDetail('cancelEvent')}
          </Button>
        ) : null}
        {!canStart && !canComplete && !canCancel ? (
          <p className={styles.fieldHint}>{tDetail('noLifecycleActions')}</p>
        ) : null}
      </div>

      <ConfirmDialog
        open={cancelOpen}
        title={tDetail('cancelConfirmTitle')}
        description={tDetail('cancelConfirmDescription')}
        confirmLabel={tDetail('confirmCancel')}
        cancelLabel={tDetail('keepEvent')}
        tone="danger"
        isLoading={saving}
        onConfirm={() => {
          setCancelOpen(false);
          onCancel();
        }}
        onClose={() => setCancelOpen(false)}
      />
    </section>
  );
}
