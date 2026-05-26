'use client';

import { ReactNode, useEffect, useRef } from 'react';
import { useFocusTrap } from '@/lib/use-focus-trap';
import styles from './drawer.module.css';

type DrawerProps = {
  open: boolean;
  title: string;
  children: ReactNode;
  onClose: () => void;
  side?: 'left' | 'right';
};

export function Drawer({ open, title, children, onClose, side = 'right' }: DrawerProps) {
  const drawerRef = useRef<HTMLElement | null>(null);
  useFocusTrap(open, drawerRef);

  useEffect(() => {
    if (!open) return undefined;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, [onClose, open]);

  if (!open) return null;

  return (
    <div className={styles.root}>
      <button type="button" className={styles.scrim} aria-label="Close drawer" onClick={onClose} />
      <aside
        ref={drawerRef}
        className={`${styles.drawer} ${styles[side]}`}
        role="dialog"
        aria-modal="true"
        aria-labelledby="admin-drawer-title"
      >
        <header className={styles.header}>
          <h2 id="admin-drawer-title">{title}</h2>
          <button type="button" className={styles.close} aria-label="Close drawer" onClick={onClose}>
            ×
          </button>
        </header>
        <div className={styles.body}>{children}</div>
      </aside>
    </div>
  );
}
