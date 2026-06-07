'use client';

import { useEffect } from 'react';
import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui';
import { AdminShell } from '@/features/admin-shell';
import { adminNavigation } from '@/features/admin-shell/config/navigation';
import { useNavItemLabel } from '@/lib/i18n';
import { clientLogger, getErrorReference } from '@/lib/observability';
import type { NavItemKey } from '@/features/admin-shell/types';
import styles from './dashboard-segment-error.module.css';

type DashboardSegmentErrorProps = {
  error: Error;
  reset: () => void;
  title?: string;
  activeItem: NavItemKey;
  heading?: string;
  message?: string;
};

export function DashboardSegmentError({
  error,
  reset,
  title: titleProp,
  activeItem,
  heading: headingProp,
  message: messageProp,
}: DashboardSegmentErrorProps) {
  const tCommon = useTranslations('common');
  const tErrors = useTranslations('errors');
  const navItem = adminNavigation.find((item) => item.key === activeItem);
  const navTitle = useNavItemLabel(navItem?.labelKey ?? activeItem);
  const title = titleProp ?? navTitle;
  const heading = headingProp ?? tErrors('segmentDefaultHeading');
  const message = messageProp ?? tErrors('segmentDefaultMessage');
  const reference = getErrorReference(error);

  useEffect(() => {
    clientLogger.error('dashboard_segment_error', {
      segment: activeItem,
      message: error.message,
      name: error.name,
      ...(reference !== undefined ? { requestId: reference } : {}),
    });
  }, [error, activeItem, reference]);

  return (
    <AdminShell title={title} activeItem={activeItem}>
      <section className={styles.card} role="alert">
        <h1 className={styles.title}>{heading}</h1>
        <p className={styles.text}>{message}</p>
        {reference ? (
          <p className={styles.text}>{tCommon('reference', { id: reference })}</p>
        ) : null}
        <div className={styles.actions}>
          <Button type="button" onClick={reset}>
            {tCommon('retry')}
          </Button>
          <Button type="button" variant="outline" onClick={() => window.location.assign('/dashboard')}>
            {tCommon('goToOverview')}
          </Button>
        </div>
      </section>
    </AdminShell>
  );
}
