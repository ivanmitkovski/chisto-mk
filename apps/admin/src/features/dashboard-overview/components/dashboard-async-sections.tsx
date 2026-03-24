import Link from 'next/link';
import { cache } from 'react';
import { SkeletonCard, SkeletonTable } from '@/components/ui';
import { ApiError } from '@/lib/api';
import { DashboardErrorBoundary } from './dashboard-error-boundary';
import { DashboardSectionWrapper } from './dashboard-section-wrapper';
import { DashboardLastUpdated } from './dashboard-last-updated';
import { DashboardRefreshButton } from './dashboard-refresh-button';
import { DashboardSectionError } from './dashboard-section-error';
import { DashboardSSEStatusIndicator } from './dashboard-sse-status-indicator';
import { getDashboardOverview } from '../data/adapters/dashboard-adapter';
import { QuickActionsDropdown } from './quick-actions-dropdown';
import { RecentActivityFeed } from './recent-activity-feed';
import { ReportsTrendChart } from './reports-trend-chart';
import { StatsOverview } from './stats-overview';
import { UpcomingCleanupsCard } from './upcoming-cleanups-card';
import { getReports, ReportsList } from '@/features/reports';
import styles from './dashboard-async-sections.module.css';

const getOverviewCached = cache(getDashboardOverview);
const getReportsCached = cache(getReports);

const CONNECTION_ERROR_MESSAGE =
  'Cannot reach API. Ensure the API is running and NEXT_PUBLIC_API_BASE_URL is correct.';

function isConnectionError(error: unknown): boolean {
  if (!(error instanceof Error)) return false;
  const msg = error.message?.toLowerCase() ?? '';
  const causeStr = error.cause?.toString() ?? '';
  return (
    msg.includes('fetch') || msg.includes('network') || causeStr.includes('ECONNREFUSED')
  );
}

function getErrorDetails(error: unknown, fallback: string): {
  message: string;
  showSignInLink: boolean;
} {
  if (process.env.NODE_ENV === 'development' && error instanceof Error) {
    console.error('[Dashboard]', fallback, error);
  }
  if (error instanceof ApiError) {
    if (error.status === 401 || error.status === 403) {
      return {
        message: 'Session expired or access denied. The access token may have expired (default 15 min). Sign in again.',
        showSignInLink: true,
      };
    }
    if (error.status >= 500) {
      return { message: 'API server error. Please try again later.', showSignInLink: false };
    }
  }
  if (isConnectionError(error)) {
    return { message: CONNECTION_ERROR_MESSAGE, showSignInLink: false };
  }
  return { message: fallback, showSignInLink: false };
}

export async function StatsSection() {
  try {
    const overview = await getOverviewCached();
    return (
      <DashboardSectionWrapper delay={0}>
        <DashboardErrorBoundary sectionName="Statistics">
          <StatsOverview stats={overview.stats} />
        </DashboardErrorBoundary>
      </DashboardSectionWrapper>
    );
  } catch (err) {
    return <DashboardSectionError {...getErrorDetails(err, 'Statistics failed to load.')} />;
  }
}

export function StatsFallback() {
  return (
    <div className={styles.statsSkeleton} aria-hidden>
      {Array.from({ length: 4 }).map((_, i) => (
        <div key={i} className={styles.statBar} />
      ))}
    </div>
  );
}

export async function ReportsSection() {
  try {
    const reports = await getReportsCached();
    const highPriorityCount = reports.filter(
      (r) => r.status === 'NEW' || r.status === 'IN_REVIEW',
    ).length;

    return (
      <DashboardSectionWrapper delay={0}>
        <section
          id="reports-section"
          className={styles.reportsSection}
          aria-labelledby="reports-heading"
        >
          <span className={styles.sectionLabel}>Queue</span>
        <div className={styles.reportsHeader}>
          <div>
            <h2 id="reports-heading" className={styles.sectionTitle}>
              Reports
            </h2>
            {highPriorityCount > 0 ? (
              <p className={styles.reportsSubline}>
                {highPriorityCount} report{highPriorityCount !== 1 ? 's' : ''} need attention
              </p>
            ) : null}
          </div>
          <div className={styles.reportsHeaderActions}>
            <div className={styles.statusPill} role="status">
              <DashboardLastUpdated />
              <DashboardSSEStatusIndicator />
              <DashboardRefreshButton />
            </div>
            <Link href="/dashboard/reports" className={styles.viewAllLink}>
              View all reports
            </Link>
          </div>
        </div>
        <DashboardErrorBoundary sectionName="Reports table">
          <ReportsList
            reports={reports}
            variant="overview"
            embedded
            maxRows={5}
            prioritizePending
          />
        </DashboardErrorBoundary>
        </section>
      </DashboardSectionWrapper>
    );
  } catch (err) {
    return (
      <section id="reports-section" className={styles.reportsSection} aria-labelledby="reports-heading">
        <span className={styles.sectionLabel}>Queue</span>
        <div className={styles.reportsHeader}>
          <h2 id="reports-heading" className={styles.sectionTitle}>
            Reports
          </h2>
          <div className={styles.reportsHeaderActions}>
            <div className={styles.statusPill} role="status">
              <DashboardLastUpdated />
              <DashboardSSEStatusIndicator />
              <DashboardRefreshButton />
            </div>
            <Link href="/dashboard/reports" className={styles.viewAllLink}>
              View all reports
            </Link>
          </div>
        </div>
        <DashboardSectionError
          {...getErrorDetails(err, 'Reports table failed to load.')}
        />
      </section>
    );
  }
}

export function ReportsFallback() {
  return (
    <section className={styles.reportsSection} aria-busy>
      <div className={styles.reportsHeaderSkeleton} />
      <SkeletonTable rows={5} cols={4} />
    </section>
  );
}

export async function InsightsSection() {
  try {
    const overview = await getOverviewCached();
    return (
      <DashboardSectionWrapper delay={0.05}>
        <section
          id="insights-section"
          className={styles.insightsSection}
          aria-labelledby="insights-heading"
        >
          <h2 id="insights-heading" className={styles.insightsHeading}>
            Insights
          </h2>
          <div className={styles.insightsRow}>
            <DashboardSectionWrapper delay={0} className={styles.insightCardWrapper}>
              <DashboardErrorBoundary sectionName="Reports trend">
                <ReportsTrendChart data={overview.reportsTrend} />
              </DashboardErrorBoundary>
            </DashboardSectionWrapper>
            <DashboardSectionWrapper delay={0.05} className={styles.insightCardWrapper}>
              <DashboardErrorBoundary sectionName="Recent activity">
                <RecentActivityFeed items={overview.recentActivity} />
              </DashboardErrorBoundary>
            </DashboardSectionWrapper>
            <DashboardSectionWrapper delay={0.1} className={styles.insightCardWrapper}>
              <DashboardErrorBoundary sectionName="Cleanup events">
                <UpcomingCleanupsCard
                  upcoming={overview.cleanupEvents.upcoming}
                  completed={overview.cleanupEvents.completed}
                  upcomingEvents={overview.cleanupEvents.upcomingEvents}
                />
              </DashboardErrorBoundary>
            </DashboardSectionWrapper>
          </div>
        </section>
      </DashboardSectionWrapper>
    );
  } catch (err) {
    return (
      <section
        id="insights-section"
        className={styles.insightsSection}
        aria-labelledby="insights-heading"
      >
        <h2 id="insights-heading" className={styles.insightsHeading}>
          Insights
        </h2>
        <div className={styles.insightsError}>
          <DashboardSectionError {...getErrorDetails(err, 'Insights failed to load.')} />
        </div>
      </section>
    );
  }
}

export function InsightsFallback() {
  return (
    <section className={styles.insightsSection} aria-busy>
      <div className={styles.insightsHeadingSkeleton} />
      <div className={styles.insightsRow}>
        <SkeletonCard lines={3} />
        <SkeletonCard lines={4} />
        <SkeletonCard lines={2} />
      </div>
    </section>
  );
}

/** Fetches dashboard data once. On error (e.g. API unreachable), shows a single standardized error. */
export async function DashboardDataOrError({
  children,
}: {
  children: React.ReactNode;
}) {
  try {
    await Promise.all([getOverviewCached(), getReportsCached()]);
    return <>{children}</>;
  } catch (err) {
    return (
      <div className={styles.dataErrorWrap}>
        <DashboardSectionError {...getErrorDetails(err, 'Dashboard failed to load.')} />
      </div>
    );
  }
}

/** Combined fallback for the full dashboard content load. */
export function DashboardContentFallback() {
  return (
    <>
      <header className={styles.contentFallbackHeader} aria-busy>
        <div className={styles.contentFallbackStatsWrap}>
          <StatsFallback />
        </div>
        <QuickActionsDropdown />
      </header>
      <main>
        <ReportsFallback />
        <InsightsFallback />
      </main>
    </>
  );
}
