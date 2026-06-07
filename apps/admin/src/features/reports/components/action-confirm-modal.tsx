'use client';

import { useEffect, useId, useRef } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Modal } from '@/components/ui';
import styles from './action-confirm-modal.module.css';

type ConfirmTone = 'default' | 'danger';
type RejectionReasonOption = {
  value: string;
  label: string;
};

type ActionConfirmModalProps = {
  isOpen: boolean;
  title: string;
  description: string;
  confirmLabel: string;
  confirmTone?: ConfirmTone;
  cancelLabel?: string;
  requireReason?: boolean;
  reasonLabel?: string;
  reasonOptions?: ReadonlyArray<RejectionReasonOption>;
  selectedReason?: string;
  reasonError?: string | null;
  notesLabel?: string;
  notesPlaceholder?: string;
  notesValue?: string;
  isConfirming?: boolean;
  onSelectedReasonChange?: ((value: string) => void) | undefined;
  onNotesChange?: ((value: string) => void) | undefined;
  onCancel: () => void;
  onConfirm: () => void;
};

export function ActionConfirmModal({
  isOpen,
  title,
  description,
  confirmLabel,
  confirmTone = 'default',
  cancelLabel,
  requireReason = false,
  reasonLabel,
  reasonOptions = [],
  selectedReason = '',
  reasonError = null,
  notesLabel,
  notesPlaceholder,
  notesValue = '',
  isConfirming = false,
  onSelectedReasonChange,
  onNotesChange,
  onCancel,
  onConfirm,
}: ActionConfirmModalProps) {
  const tCommon = useTranslations('common');
  const tReject = useTranslations('reports.rejectionReasons');
  const resolvedCancelLabel = cancelLabel ?? tCommon('cancel');
  const resolvedReasonLabel = reasonLabel ?? tReject('label');
  const resolvedNotesLabel = notesLabel ?? tReject('notesLabel');
  const resolvedNotesPlaceholder = notesPlaceholder ?? tReject('notesPlaceholder');
  const reasonInputRef = useRef<HTMLSelectElement>(null);
  const notesTextareaRef = useRef<HTMLTextAreaElement>(null);
  const reasonSelectId = useId();
  const reasonErrorId = useId();
  const notesId = useId();
  const showNotesField = requireReason || Boolean(onNotesChange);
  const showReasonBlock = requireReason;
  const showBody = showReasonBlock || showNotesField;

  useEffect(() => {
    if (!isOpen) return;
    const timeoutId = window.setTimeout(() => {
      if (requireReason) {
        reasonInputRef.current?.focus();
        return;
      }
      if (onNotesChange) {
        notesTextareaRef.current?.focus();
      }
    }, 0);
    return () => window.clearTimeout(timeoutId);
  }, [isOpen, requireReason, onNotesChange]);

  return (
    <Modal
      open={isOpen}
      title={title}
      description={description}
      onClose={onCancel}
      footer={
        <>
          <Button variant="outline" onClick={onCancel} disabled={isConfirming}>
            {resolvedCancelLabel}
          </Button>
          <Button
            variant={confirmTone === 'danger' ? 'danger' : 'solid'}
            onClick={onConfirm}
            isLoading={isConfirming}
          >
            {confirmLabel}
          </Button>
        </>
      }
    >
      {showBody ? (
        <div className={styles.form}>
          {showReasonBlock ? (
            <>
              <label className={styles.label} htmlFor={reasonSelectId}>
                {resolvedReasonLabel}
              </label>
              <select
                ref={reasonInputRef}
                id={reasonSelectId}
                className={styles.select}
                value={selectedReason}
                onChange={(event) => onSelectedReasonChange?.(event.target.value)}
                aria-invalid={Boolean(reasonError)}
                aria-describedby={reasonError ? reasonErrorId : undefined}
              >
                <option value="">{tReject('selectPlaceholder')}</option>
                {reasonOptions.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
              {reasonError ? (
                <p id={reasonErrorId} className={styles.error}>
                  {reasonError}
                </p>
              ) : null}
            </>
          ) : null}
          {showNotesField ? (
            <>
              <label className={styles.label} htmlFor={notesId}>
                {resolvedNotesLabel}
              </label>
              <textarea
                ref={onNotesChange ? notesTextareaRef : undefined}
                id={notesId}
                className={styles.textarea}
                value={notesValue}
                placeholder={resolvedNotesPlaceholder}
                onChange={(event) => onNotesChange?.(event.target.value)}
              />
            </>
          ) : null}
        </div>
      ) : null}
    </Modal>
  );
}
