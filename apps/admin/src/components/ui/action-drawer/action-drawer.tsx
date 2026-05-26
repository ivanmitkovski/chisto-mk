'use client';

import type { ReactNode } from 'react';
import { Button } from '../button';
import { Drawer } from '../drawer';
import styles from './action-drawer.module.css';

export function ActionDrawer({
  open,
  title,
  children,
  primaryLabel,
  secondaryLabel = 'Cancel',
  isLoading,
  onPrimary,
  onClose,
}: {
  open: boolean;
  title: string;
  children: ReactNode;
  primaryLabel: string;
  secondaryLabel?: string;
  isLoading?: boolean;
  onPrimary: () => void;
  onClose: () => void;
}) {
  return (
    <Drawer open={open} title={title} onClose={onClose}>
      <div className={styles.body}>{children}</div>
      <footer className={styles.footer}>
        <Button type="button" variant="outline" onClick={onClose} disabled={isLoading}>
          {secondaryLabel}
        </Button>
        <Button type="button" onClick={onPrimary} isLoading={Boolean(isLoading)}>
          {primaryLabel}
        </Button>
      </footer>
    </Drawer>
  );
}
