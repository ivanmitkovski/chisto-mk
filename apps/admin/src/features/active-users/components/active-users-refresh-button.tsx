'use client';

import { useCallback, useRef } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Icon } from '@/components/ui';
import { useWorkspaceRefresh } from '@/features/admin-shell/hooks/use-workspace-refresh';
import { useDashboardSSE } from '@/features/dashboard-overview/context/dashboard-sse-context';
import { useActiveUsersLive } from '../hooks/use-active-users-live';
import styles from './active-users-header-chrome.module.css';

const DEBOUNCE_MS = 800;

export function ActiveUsersRefreshButton() {
  const tCommon = useTranslations('common');
  const { refresh: refreshLive, isRefreshing: liveRefreshing } = useActiveUsersLive();
  const { refresh: refreshPage, isRefreshing: pageRefreshing } = useWorkspaceRefresh();
  const sseCtx = useDashboardSSE();
  const lastClickRef = useRef(0);
  const isRefreshing = liveRefreshing || pageRefreshing;

  const handleClick = useCallback(() => {
    const now = Date.now();
    if (now - lastClickRef.current < DEBOUNCE_MS) return;
    lastClickRef.current = now;
    sseCtx?.touchLastUpdated();
    refreshLive();
    refreshPage();
  }, [refreshLive, refreshPage, sseCtx]);

  return (
    <Button
      variant="icon"
      aria-label={tCommon('refresh')}
      onClick={handleClick}
      disabled={isRefreshing}
      aria-busy={isRefreshing}
    >
      <Icon
        name="refresh"
        size={16}
        {...(isRefreshing && { className: styles.spinning })}
      />
    </Button>
  );
}
