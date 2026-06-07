'use client';

import { useId } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Modal } from '@/components/ui';
import styles from './events-bulk-modal.module.css';

type EventsBulkModalProps = {
  isOpen: boolean;
  selectedCount: number;
  reason: string;
  error: string | null;
  busy: boolean;
  onReasonChange: (value: string) => void;
  onClearError: () => void;
  onClose: () => void;
  onSubmit: () => void;
};

export function EventsBulkModal({
  isOpen,
  selectedCount,
  reason,
  error,
  busy,
  onReasonChange,
  onClearError,
  onClose,
  onSubmit,
}: EventsBulkModalProps) {
  const t = useTranslations('events');
  const tCommon = useTranslations('common');
  const textareaId = useId();
  const errorId = useId();

  return (
    <Modal
      open={isOpen}
      title={t('bulk.declineSelectedTitle')}
      description={t('bulk.declineSelectedDescription', { count: selectedCount })}
      onClose={onClose}
      footer={
        <>
          <Button type="button" variant="outline" disabled={busy} onClick={onClose}>
            {tCommon('cancel')}
          </Button>
          <Button type="button" variant="danger" isLoading={busy} onClick={() => void onSubmit()}>
            {t('bulk.declineAll')}
          </Button>
        </>
      }
    >
      <textarea
        id={textareaId}
        className={styles.textarea}
        value={reason}
        onChange={(e) => {
          onReasonChange(e.target.value);
          onClearError();
        }}
        disabled={busy}
        maxLength={2000}
        aria-invalid={error ? true : undefined}
        aria-describedby={error ? errorId : undefined}
      />
      {error ? (
        <p id={errorId} className={styles.fieldError} role="alert">
          {error}
        </p>
      ) : null}
    </Modal>
  );
}
