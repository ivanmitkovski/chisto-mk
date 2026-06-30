'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { SectionState } from '@/components/ui';
import { DashboardRefreshButton } from './dashboard-refresh-button';
import styles from './dashboard-error-boundary.module.css';

type DashboardSectionErrorProps = {
  message: string;
  showSignInLink?: boolean;
};

export function DashboardSectionError({ message, showSignInLink }: DashboardSectionErrorProps) {
  const t = useTranslations('dashboard.errors');
  const tBoundary = useTranslations('dashboard.errorBoundary');

  return (
    <div className={styles.wrap}>
      <SectionState variant="error" message={message} />
      <div className={styles.actions}>
        <DashboardRefreshButton label={tBoundary('retry')} variant="ghost" className={styles.retryButton} />
        {showSignInLink ? (
          <>
            <span className={styles.separator}>·</span>
            <Link href="/login" className={styles.signInLink}>
              {t('signInAgain')}
            </Link>
          </>
        ) : null}
      </div>
    </div>
  );
}
