'use client';

import { useEffect } from 'react';
import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui';
import { useWorkspaceRefresh } from '@/features/admin-shell/hooks/use-workspace-refresh';
import styles from './operations-workspace.module.css';

const POLL_INTERVAL_MS = 60_000;

export function OperationsRefreshBar() {
  const t = useTranslations('operations');
  const tCommon = useTranslations('common');
  const { refresh, isRefreshing } = useWorkspaceRefresh();

  useEffect(() => {
    if (typeof document === 'undefined') return undefined;

    const tick = () => {
      if (!document.hidden) refresh();
    };

    const id = window.setInterval(tick, POLL_INTERVAL_MS);
    return () => window.clearInterval(id);
  }, [refresh]);

  return (
    <div className={styles.toolbar}>
      <Button variant="outline" size="sm" onClick={() => refresh()} disabled={isRefreshing} aria-busy={isRefreshing}>
        {isRefreshing ? tCommon('refreshing') : t('refreshBar.refreshAll')}
      </Button>
      <span className={styles.pollHint}>{t('refreshBar.autoRefreshHint')}</span>
    </div>
  );
}
