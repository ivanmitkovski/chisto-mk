'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { SectionState } from '@/components/ui';
import { DashboardRefreshButton } from './dashboard-refresh-button';
import styles from './dashboard-error-state.module.css';

type DashboardErrorStateProps = {
  message: string;
};

export function DashboardErrorState({ message }: DashboardErrorStateProps) {
  const t = useTranslations('dashboard.errors');

  return (
    <div className={styles.root}>
      <SectionState variant="error" message={message} />
      <div className={styles.actions}>
        <DashboardRefreshButton label={t('tryAgain')} variant="ghost" />
        <span className={styles.separator}>·</span>
        <Link href="/login" className={styles.link}>
          {t('signInAgain')}
        </Link>
      </div>
    </div>
  );
}
