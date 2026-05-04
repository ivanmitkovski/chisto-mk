'use client';

import { useEffect, useId, useRef, useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { createPortal } from 'react-dom';
import { Button } from '@/components/ui';
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
  cancelLabel = 'Cancel',
  requireReason = false,
  reasonLabel = 'Rejection reason',
  reasonOptions = [],
  selectedReason = '',
  reasonError = null,
  notesLabel = 'Additional notes (optional)',
  notesPlaceholder = 'Add optional context for audit trail',
  notesValue = '',
  isConfirming = false,
  onSelectedReasonChange,
  onNotesChange,
  onCancel,
  onConfirm,
}: ActionConfirmModalProps) {
  const [isMounted, setIsMounted] = useState(false);
  const reasonInputRef = useRef<HTMLSelectElement>(null);
  const notesTextareaRef = useRef<HTMLTextAreaElement>(null);
  const confirmButtonRef = useRef<HTMLButtonElement>(null);
  const reasonSelectId = useId();
  const reasonErrorId = useId();
  const notesId = useId();
  /** Notes row: merge (onNotesChange only) or rejection flow (requireReason always showed notes). */
  const showNotesField = requireReason || Boolean(onNotesChange);
  const showReasonBlock = requireReason;
  const showBody = showReasonBlock || showNotesField;

  useEffect(() => {
    const id = requestAnimationFrame(() => {
      requestAnimationFrame(() => setIsMounted(true));
    });
    return () => cancelAnimationFrame(id);
  }, []);

  useEffect(() => {
    if (!isOpen) {
      return;
    }

    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';

    const timeoutId = window.setTimeout(() => {
      if (requireReason) {
        reasonInputRef.current?.focus();
        return;
      }
      if (onNotesChange) {
        notesTextareaRef.current?.focus();
        return;
      }
      confirmButtonRef.current?.focus();
    }, 0);

    return () => {
      window.clearTimeout(timeoutId);
      document.body.style.overflow = previousOverflow;
    };
  }, [isOpen, requireReason, onNotesChange]);

  useEffect(() => {
    if (!isOpen) {
      return;
    }

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key !== 'Escape') {
        return;
      }

      event.preventDefault();
      onCancel();
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [isOpen, onCancel]);

  if (!isMounted || typeof document === 'undefined' || !document.body) {
    return null;
  }

  return createPortal(
    <AnimatePresence mode="sync">
      {isOpen ? (
        <motion.div
          className={styles.backdrop}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.15 }}
          onMouseDown={(event) => {
            if (event.target !== event.currentTarget) {
              return;
            }
            onCancel();
          }}
        >
          <motion.section
            className={styles.modal}
            role="dialog"
            aria-modal="true"
            aria-label={title}
            initial={{ opacity: 0, y: 8, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 8, scale: 0.98 }}
            transition={{ duration: 0.18, ease: 'easeOut' }}
          >
            <header className={styles.header}>
              <h2 className={styles.title}>{title}</h2>
              <p className={styles.description}>{description}</p>
            </header>

            {showBody ? (
              <div className={styles.body}>
                {showReasonBlock ? (
                  <>
                    <label className={styles.label} htmlFor={reasonSelectId}>
                      {reasonLabel}
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
                      <option value="">Select rejection reason</option>
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
                      {notesLabel}
                    </label>
                    <textarea
                      ref={onNotesChange ? notesTextareaRef : undefined}
                      id={notesId}
                      className={styles.textarea}
                      value={notesValue}
                      placeholder={notesPlaceholder}
                      onChange={(event) => onNotesChange?.(event.target.value)}
                    />
                  </>
                ) : null}
              </div>
            ) : null}

            <footer className={styles.footer}>
              <Button variant="outline" onClick={onCancel} disabled={isConfirming}>
                {cancelLabel}
              </Button>
              <Button
                ref={confirmButtonRef}
                onClick={onConfirm}
                isLoading={isConfirming}
                className={confirmTone === 'danger' ? styles.dangerButton : undefined}
              >
                {confirmLabel}
              </Button>
            </footer>
          </motion.section>
        </motion.div>
      ) : null}
    </AnimatePresence>,
    document.body,
  );
}
