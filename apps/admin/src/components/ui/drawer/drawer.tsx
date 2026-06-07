'use client';

import { ReactNode, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { useTranslations } from 'next-intl';
import { useFocusTrap } from '@/lib/utils';
import { useOverlayAnimation } from '@/lib/utils/use-overlay-animation';
import styles from './drawer.module.css';

type DrawerProps = {
  open: boolean;
  title: string;
  children: ReactNode;
  onClose: () => void;
  side?: 'left' | 'right';
};

export function Drawer({ open, title, children, onClose, side = 'right' }: DrawerProps) {
  const t = useTranslations('common');
  const drawerRef = useRef<HTMLElement | null>(null);
  const { mounted, phase, finishExit } = useOverlayAnimation(open);
  useFocusTrap(mounted && phase !== 'exit', drawerRef);

  useEffect(() => {
    if (!mounted || phase === 'exit') return undefined;
    const previous = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', onKeyDown);
    window.setTimeout(() => drawerRef.current?.focus(), 0);
    return () => {
      document.body.style.overflow = previous;
      document.removeEventListener('keydown', onKeyDown);
    };
  }, [mounted, onClose, phase]);

  const handlePanelAnimationEnd = (event: React.AnimationEvent<HTMLElement>) => {
    if (phase !== 'exit' || event.target !== drawerRef.current) return;
    finishExit();
  };

  if (!mounted) return null;

  if (typeof document === 'undefined' || !document.body) {
    return null;
  }

  return createPortal(
    <div className={styles.root} data-state={phase}>
      <button type="button" className={styles.scrim} aria-label={t('closeDrawer')} onClick={onClose} />
      <aside
        ref={drawerRef}
        className={`${styles.drawer} ${styles[side]}`}
        role="dialog"
        aria-modal="true"
        aria-labelledby="admin-drawer-title"
        tabIndex={-1}
        data-side={side}
        onAnimationEnd={handlePanelAnimationEnd}
      >
        <header className={styles.header}>
          <h2 id="admin-drawer-title">{title}</h2>
          <button type="button" className={styles.close} aria-label={t('closeDrawer')} onClick={onClose}>
            ×
          </button>
        </header>
        <div className={styles.body}>{children}</div>
      </aside>
    </div>,
    document.body,
  );
}
