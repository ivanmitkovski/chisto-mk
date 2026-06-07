'use client';

import type { ReactNode } from 'react';
import { useTranslations } from 'next-intl';
import styles from './workspace-refresh-overlay.module.css';

type WorkspaceRefreshOverlayProps = {
  isRefreshing: boolean;
  children: ReactNode;
};

export function WorkspaceRefreshOverlay({ isRefreshing, children }: WorkspaceRefreshOverlayProps) {
  const t = useTranslations('common');

  return (
    <div className={styles.wrap}>
      {children}
      {isRefreshing ? (
        <div className={styles.overlay} aria-busy="true" aria-live="polite" role="status">
          <span className={styles.label}>{t('refreshing')}</span>
        </div>
      ) : null}
    </div>
  );
}
