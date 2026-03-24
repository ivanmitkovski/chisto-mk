import Link from 'next/link';
import { SectionState } from '@/components/ui';
import { DashboardRefreshButton } from './dashboard-refresh-button';
import styles from './dashboard-error-boundary.module.css';

type DashboardSectionErrorProps = {
  message: string;
  showSignInLink?: boolean;
};

export function DashboardSectionError({ message, showSignInLink }: DashboardSectionErrorProps) {
  return (
    <div className={styles.wrap}>
      <SectionState variant="error" message={message} />
      <div className={styles.actions}>
        <DashboardRefreshButton label="Retry" variant="ghost" className={styles.retryButton} />
        {showSignInLink ? (
          <>
            <span className={styles.separator}>·</span>
            <Link href="/login" className={styles.signInLink}>
              Sign in again
            </Link>
          </>
        ) : null}
      </div>
    </div>
  );
}
