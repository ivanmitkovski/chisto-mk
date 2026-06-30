'use client';

import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui';
import { useOperationsLive } from './operations-live-provider';
import styles from './operations-workspace.module.css';

export function OperationsRefreshBar() {
  const t = useTranslations('operations');
  const tCommon = useTranslations('common');
  const { refresh, isRefreshing } = useOperationsLive();

  return (
    <div className={styles.toolbar}>
      <Button variant="outline" size="sm" onClick={() => refresh()} disabled={isRefreshing} aria-busy={isRefreshing}>
        {isRefreshing ? tCommon('refreshing') : t('refreshBar.refreshAll')}
      </Button>
      <span className={styles.pollHint}>{t('refreshBar.autoRefreshHint')}</span>
    </div>
  );
}
