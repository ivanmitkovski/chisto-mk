'use client';

import { useCallback, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Button, Icon } from '@/components/ui';
import styles from './dashboard-refresh-button.module.css';

const DEBOUNCE_MS = 800;

type DashboardRefreshButtonProps = {
  label?: 'Refresh' | 'Retry' | 'Try again';
  variant?: 'icon' | 'ghost';
  className?: string;
};

export function DashboardRefreshButton({
  label = 'Refresh',
  variant = 'icon',
  className,
}: DashboardRefreshButtonProps) {
  const router = useRouter();
  const [isRefreshing, setIsRefreshing] = useState(false);
  const lastClickRef = useRef(0);

  const handleClick = useCallback(() => {
    const now = Date.now();
    if (now - lastClickRef.current < DEBOUNCE_MS) {
      return;
    }
    lastClickRef.current = now;
    setIsRefreshing(true);
    router.refresh();
    window.setTimeout(() => setIsRefreshing(false), DEBOUNCE_MS);
  }, [router]);

  if (variant === 'icon') {
    return (
      <Button
        variant="icon"
        aria-label={label}
        className={className}
        onClick={handleClick}
        disabled={isRefreshing}
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
    >
      {isRefreshing ? 'Refreshing…' : label}
    </Button>
  );
}
