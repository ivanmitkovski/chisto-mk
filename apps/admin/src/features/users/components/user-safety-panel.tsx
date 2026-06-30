'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { Card } from '@/components/ui';
import type { UserSafetySummary } from '@/features/users/data/users-adapter';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import styles from './user-safety-panel.module.css';

type UserSafetyPanelProps = {
  userId: string;
  email: string;
  summary: UserSafetySummary;
};

export function UserSafetyPanel({ userId, email, summary }: UserSafetyPanelProps) {
  const t = useTranslations('users');
  const locale = useAdminBcp47Locale();

  return (
    <Card padding="md">
      <div className={styles.grid}>
        <div className={styles.stat}>
          <p className={styles.label}>{t('detail.safety.ugcReports')}</p>
          <p className={styles.value}>{summary.ugcReportsAsSubjectCount}</p>
          <Link
            href={`/dashboard/moderation/ugc?subjectType=user&search=${encodeURIComponent(userId)}`}
            className={styles.link}
          >
            {t('detail.safety.viewUgcReports')}
          </Link>
        </div>
        <div className={styles.stat}>
          <p className={styles.label}>{t('detail.safety.reportsFiled')}</p>
          <p className={styles.value}>{summary.reportsFiledCount}</p>
          <Link
            href={`/dashboard/reports?search=${encodeURIComponent(email)}`}
            className={styles.link}
          >
            {t('detail.safety.viewReports')}
          </Link>
        </div>
        <div className={styles.stat}>
          <p className={styles.label}>{t('detail.safety.blocksGiven')}</p>
          <p className={styles.value}>{summary.blocksGivenCount}</p>
        </div>
        <div className={styles.stat}>
          <p className={styles.label}>{t('detail.safety.blocksReceived')}</p>
          <p className={styles.value}>{summary.blocksReceivedCount}</p>
        </div>
      </div>

      {summary.recentUgcReports.length > 0 ? (
        <section className={styles.recent}>
          <h3 className={styles.recentTitle}>{t('detail.safety.recentUgc')}</h3>
          <ul className={styles.list}>
            {summary.recentUgcReports.map((report) => (
              <li key={report.id}>
                <Link href={`/dashboard/moderation/ugc?reportId=${encodeURIComponent(report.id)}`}>
                  {report.reason}
                </Link>
                <span className={styles.meta}>
                  {report.status} · {formatAdminDateTime(report.createdAt, locale)}
                </span>
              </li>
            ))}
          </ul>
        </section>
      ) : (
        <p className={styles.empty}>{t('detail.safety.noRecentUgc')}</p>
      )}
    </Card>
  );
}
