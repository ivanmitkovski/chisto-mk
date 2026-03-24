'use client';

import Link from 'next/link';
import type { ReportRow } from '@/features/reports/types';
import { ReportsList } from './reports-list';
import styles from '@/app/dashboard/reports/reports-page.module.css';

type ReportsPageClientProps = {
  reports: ReportRow[];
  siteIdFilter?: string;
};

export function ReportsPageClient({ reports, siteIdFilter }: ReportsPageClientProps) {
  return (
    <div className={styles.page}>
      <a href="#reports-section" className="skipLink">
        Skip to reports list
      </a>
      {siteIdFilter && (
        <p className={styles.siteFilterBanner}>
          Filtered by site.{' '}
          <Link href="/dashboard/reports" className={styles.siteFilterLink}>
            Show all reports
          </Link>
        </p>
      )}
      <ReportsList reports={reports} />
    </div>
  );
}
