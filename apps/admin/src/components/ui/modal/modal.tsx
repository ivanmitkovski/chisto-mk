'use client';

import { ReactNode, useEffect, useRef } from 'react';
import { useFocusTrap } from '@/lib/use-focus-trap';
import styles from './modal.module.css';

type ModalProps = {
  open: boolean;
  title: string;
  description?: string;
  children: ReactNode;
  footer?: ReactNode;
  onClose: () => void;
};

export function Modal({ open, title, description, children, footer, onClose }: ModalProps) {
  const dialogRef = useRef<HTMLDivElement | null>(null);
  useFocusTrap(open, dialogRef);

  useEffect(() => {
    if (!open) return undefined;
    const previous = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', onKeyDown);
    window.setTimeout(() => dialogRef.current?.focus(), 0);
    return () => {
      document.body.style.overflow = previous;
      document.removeEventListener('keydown', onKeyDown);
    };
  }, [onClose, open]);

  if (!open) return null;

  return (
    <div className={styles.root}>
      <button type="button" className={styles.scrim} aria-label="Close dialog" onClick={onClose} />
      <div
        ref={dialogRef}
        className={styles.dialog}
        role="dialog"
        aria-modal="true"
        aria-labelledby="admin-modal-title"
        aria-describedby={description ? 'admin-modal-description' : undefined}
        tabIndex={-1}
      >
        <header className={styles.header}>
          <div>
            <h2 id="admin-modal-title" className={styles.title}>
              {title}
            </h2>
            {description ? (
              <p id="admin-modal-description" className={styles.description}>
                {description}
              </p>
            ) : null}
          </div>
          <button type="button" className={styles.close} aria-label="Close dialog" onClick={onClose}>
            ×
          </button>
        </header>
        <div className={styles.body}>{children}</div>
        {footer ? <footer className={styles.footer}>{footer}</footer> : null}
      </div>
    </div>
  );
}
