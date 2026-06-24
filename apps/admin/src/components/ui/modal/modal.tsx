'use client';

import { ReactNode, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { useTranslations } from 'next-intl';
import { useFocusTrap } from '@/lib/utils';
import { useOverlayAnimation } from '@/lib/utils/use-overlay-animation';
import styles from './modal.module.css';

type ModalProps = {
  open: boolean;
  title: string;
  description?: string;
  children?: ReactNode;
  footer?: ReactNode;
  onClose: () => void;
};

export function Modal({ open, title, description, children, footer, onClose }: ModalProps) {
  const t = useTranslations('common');
  const dialogRef = useRef<HTMLDivElement | null>(null);
  const { mounted, phase, finishExit } = useOverlayAnimation(open);
  useFocusTrap(mounted && phase !== 'exit', dialogRef);

  useEffect(() => {
    if (!mounted || phase === 'exit') return undefined;
    const previous = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', onKeyDown);
    const focusTimeoutId = window.setTimeout(() => dialogRef.current?.focus(), 0);
    return () => {
      window.clearTimeout(focusTimeoutId);
      document.body.style.overflow = previous;
      document.removeEventListener('keydown', onKeyDown);
    };
  }, [mounted, onClose, phase]);

  const handlePanelAnimationEnd = (event: React.AnimationEvent<HTMLDivElement>) => {
    if (phase !== 'exit' || event.target !== dialogRef.current) return;
    finishExit();
  };

  if (!mounted) return null;

  if (typeof document === 'undefined' || !document.body) {
    return null;
  }

  return createPortal(
    <div className={styles.root} data-state={phase}>
      <button type="button" className={styles.scrim} aria-label={t('closeDialog')} onClick={onClose} />
      <div
        ref={dialogRef}
        className={styles.dialog}
        role="dialog"
        aria-modal="true"
        aria-labelledby="admin-modal-title"
        aria-describedby={description ? 'admin-modal-description' : undefined}
        tabIndex={-1}
        onAnimationEnd={handlePanelAnimationEnd}
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
          <button type="button" className={styles.close} aria-label={t('closeDialog')} onClick={onClose}>
            ×
          </button>
        </header>
        {children != null ? <div className={styles.body}>{children}</div> : null}
        {footer ? <footer className={styles.footer}>{footer}</footer> : null}
      </div>
    </div>,
    document.body,
  );
}
