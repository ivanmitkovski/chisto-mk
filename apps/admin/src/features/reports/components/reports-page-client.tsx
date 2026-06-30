'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { PageHeader } from '@/components/ui';
import type { ReportRow } from '@/features/reports/types';
import type { ReportsQueueSummary } from '@/features/reports/data/reports-adapter';
import { ReportsList } from './reports-list';
import styles from './reports-page.module.css';

type ReportsPageClientProps = {
  reports: ReportRow[];
  meta?: { page: number; limit: number; total: number };
  queueSummary?: ReportsQueueSummary;
  initialSearch?: string;
  siteIdFilter?: string;
};

export function ReportsPageClient({
  reports,
  meta,
  queueSummary,
  initialSearch = '',
  siteIdFilter,
}: ReportsPageClientProps) {
  const t = useTranslations('reports');
  const tCommon = useTranslations('common');

  return (
    <div className={styles.page}>
      <PageHeader title={t('pageTitle')} description={t('pageDescription')} />
      <a href="#reports-section" className="skipLink">
        {tCommon('skipToReports')}
      </a>
      {siteIdFilter && (
        <p className={styles.siteFilterBanner}>
          {t('siteFilter.banner')}{' '}
          <Link href="/dashboard/reports" className={styles.siteFilterLink}>
            {t('siteFilter.showAll')}
          </Link>
        </p>
      )}
      <ReportsList
        reports={reports}
        initialSearch={initialSearch}
        {...(meta ? { serverMeta: meta } : {})}
        {...(queueSummary ? { queueSummary } : {})}
        {...(siteIdFilter ? { siteIdFilter } : {})}
      />
    </div>
  );
}
