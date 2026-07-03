'use client';

import { ReactNode, useEffect, useRef, type RefObject } from 'react';
import { createPortal } from 'react-dom';
import { useTranslations } from 'next-intl';
import { useFocusTrap } from '@/lib/utils';
import { useOverlayAnimation } from '@/lib/utils/use-overlay-animation';
import styles from './modal.module.css';

const FOCUSABLE_SELECTOR =
  'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])';

function focusInitialElement(
  dialog: HTMLDivElement,
  initialFocusRef?: RefObject<HTMLElement | null>,
): void {
  const preferred = initialFocusRef?.current;
  if (preferred && dialog.contains(preferred)) {
    preferred.focus();
    return;
  }

  const firstFocusable = dialog.querySelector<HTMLElement>(FOCUSABLE_SELECTOR);
  if (firstFocusable) {
    firstFocusable.focus();
    return;
  }

  dialog.focus();
}

type ModalProps = {
  open: boolean;
  title: string;
  description?: string;
  children?: ReactNode;
  footer?: ReactNode;
  onClose: () => void;
  initialFocusRef?: RefObject<HTMLElement | null>;
};

export function Modal({
  open,
  title,
  description,
  children,
  footer,
  onClose,
  initialFocusRef,
}: ModalProps) {
  const t = useTranslations('common');
  const dialogRef = useRef<HTMLDivElement | null>(null);
  const onCloseRef = useRef(onClose);
  onCloseRef.current = onClose;
  const { mounted, phase, finishExit } = useOverlayAnimation(open);
  useFocusTrap(mounted && phase !== 'exit', dialogRef);

  useEffect(() => {
    if (!mounted || phase === 'exit') return undefined;
    const previous = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onCloseRef.current();
    };
    document.addEventListener('keydown', onKeyDown);
    return () => {
      document.body.style.overflow = previous;
      document.removeEventListener('keydown', onKeyDown);
    };
  }, [mounted, phase]);

  useEffect(() => {
    if (!mounted || phase !== 'open') return undefined;
    const focusTimeoutId = window.setTimeout(() => {
      const dialog = dialogRef.current;
      if (!dialog) return;
      focusInitialElement(dialog, initialFocusRef);
    }, 0);
    return () => {
      window.clearTimeout(focusTimeoutId);
    };
  }, [initialFocusRef, mounted, phase]);

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
