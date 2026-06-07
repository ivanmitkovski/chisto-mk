'use client';

import { useId } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Modal } from '@/components/ui';
import styles from './decline-reason-modal.module.css';

type DeclineReasonModalProps = {
  open: boolean;
  reason: string;
  reasonError: string | null;
  saving: boolean;
  onReasonChange: (value: string) => void;
  onClose: () => void;
  onSubmit: () => void;
};

export function DeclineReasonModal({
  open,
  reason,
  reasonError,
  saving,
  onReasonChange,
  onClose,
  onSubmit,
}: DeclineReasonModalProps) {
  const t = useTranslations('events');
  const tCommon = useTranslations('common');
  const textareaId = useId();
  const errorId = useId();

  return (
    <Modal
      open={open}
      title={t('decline.title')}
      description={t('decline.description')}
      onClose={onClose}
      footer={
        <>
          <Button type="button" variant="outline" disabled={saving} onClick={onClose}>
            {tCommon('cancel')}
          </Button>
          <Button type="button" variant="danger" isLoading={saving} onClick={onSubmit}>
            {t('decline.title')}
          </Button>
        </>
      }
    >
      <label className={styles.field} htmlFor={textareaId}>
        <span className={styles.fieldLabel}>{t('decline.reason')}</span>
        <textarea
          id={textareaId}
          value={reason}
          onChange={(e) => onReasonChange(e.target.value)}
          className={styles.textarea}
          rows={4}
          maxLength={2000}
          disabled={saving}
          aria-invalid={reasonError ? true : undefined}
          aria-describedby={reasonError ? errorId : undefined}
        />
        {reasonError ? (
          <span id={errorId} className={styles.fieldError} role="alert">
            {reasonError}
          </span>
        ) : null}
      </label>
    </Modal>
  );
}
