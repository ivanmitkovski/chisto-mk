'use client';

import { useCallback, useRef } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Icon } from '@/components/ui';
import { useWorkspaceRefresh } from '@/features/admin-shell/hooks/use-workspace-refresh';
import { useDashboardSSE } from '../context/dashboard-sse-context';
import styles from './dashboard-refresh-button.module.css';

const DEBOUNCE_MS = 800;

type DashboardRefreshButtonProps = {
  label?: string;
  variant?: 'icon' | 'ghost';
  className?: string;
};

export function DashboardRefreshButton({
  label,
  variant = 'icon',
  className,
}: DashboardRefreshButtonProps) {
  const tCommon = useTranslations('common');
  const tBoundary = useTranslations('dashboard.errorBoundary');
  const resolvedLabel = label ?? tCommon('refresh');
  const { refresh, isRefreshing } = useWorkspaceRefresh();
  const sseCtx = useDashboardSSE();
  const lastClickRef = useRef(0);

  const handleClick = useCallback(() => {
    const now = Date.now();
    if (now - lastClickRef.current < DEBOUNCE_MS) {
      return;
    }
    lastClickRef.current = now;
    sseCtx?.touchLastUpdated();
    refresh();
  }, [refresh, sseCtx]);

  if (variant === 'icon') {
    return (
      <Button
        variant="icon"
        aria-label={resolvedLabel}
        className={className}
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

  return (
    <Button
      variant="ghost"
      size="sm"
      className={className}
      onClick={handleClick}
      disabled={isRefreshing}
      aria-busy={isRefreshing}
    >
      {isRefreshing ? tCommon('refreshing') : (label ?? tBoundary('retry'))}
    </Button>
  );
}
