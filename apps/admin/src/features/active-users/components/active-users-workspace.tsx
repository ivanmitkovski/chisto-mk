'use client';

import type { ReactNode } from 'react';
import { useMemo } from 'react';
import { useTranslations } from 'next-intl';
import { PageHeader } from '@/components/ui';
import { DashboardSSEStatusIndicator } from '@/features/dashboard-overview/components/dashboard-sse-status-indicator';
import { ActiveUsersLastUpdated } from './active-users-last-updated';
import { ActiveUsersRefreshButton } from './active-users-refresh-button';
import type {
  ActiveUserRow,
  ActiveUsersSummary,
  AdminAlertRule,
  RealtimeAnalytics,
} from '../data/active-users.types';
import type { ActiveUsersLoadErrors } from '../hooks/use-active-users-live';
import { ActiveUsersLiveProvider } from '../hooks/use-active-users-live';
import { useActiveUsersUrl } from '../hooks/use-active-users-url';
import { ActiveUsersSseBridge } from './active-users-sse-bridge';
import { ActiveUsersSummarySection } from './active-users-summary';
import { ActiveUsersToolbar } from './active-users-toolbar';
import { ActiveUsersTable } from './active-users-table';
import { ActivityFeedPanel } from './activity-feed-panel';
import { AlertsPanel } from './alerts-panel';
import styles from './active-users-workspace.module.css';

export type ActiveUsersWorkspaceProps = {
  initialSummary: ActiveUsersSummary | null;
  initialRows: ActiveUserRow[];
  initialListTotal: number;
  initialRealtime: RealtimeAnalytics;
  initialAlertRules: AdminAlertRule[];
  initialFeedType: string;
  listFilters: {
    page: number;
    limit: number;
    search?: string;
    status?: string;
    platform?: string;
  };
  loadErrors?: ActiveUsersLoadErrors & {
    alerts?: string;
  };
  engagementSection?: ReactNode;
  geoSection?: ReactNode;
};

export function ActiveUsersWorkspace(props: ActiveUsersWorkspaceProps) {
  const t = useTranslations('activeUsers');
  const url = useActiveUsersUrl();

  const listFilters = useMemo(
    () => ({
      page: url.page,
      limit: url.limit,
      ...(url.debouncedSearch ? { search: url.debouncedSearch } : {}),
      ...(url.status ? { status: url.status } : {}),
      ...(url.platform ? { platform: url.platform } : {}),
    }),
    [url.page, url.limit, url.debouncedSearch, url.status, url.platform],
  );

  return (
    <ActiveUsersLiveProvider
      initialSummary={props.initialSummary}
      initialRows={props.initialRows}
      initialListTotal={props.initialListTotal}
      initialRealtime={props.initialRealtime}
      initialFeedType={props.initialFeedType}
      initialAlertRules={props.initialAlertRules}
      listFilters={listFilters}
      loadErrors={{
        ...(props.loadErrors?.summary ? { summary: props.loadErrors.summary } : {}),
        ...(props.loadErrors?.list ? { list: props.loadErrors.list } : {}),
      }}
    >
      <ActiveUsersSseBridge />
      <div className={styles.root}>
        <PageHeader
          title={t('pageTitle')}
          description={t('pageDescription')}
          actions={
            <div className={styles.headerActions}>
              <DashboardSSEStatusIndicator />
              <ActiveUsersLastUpdated />
              <ActiveUsersRefreshButton />
            </div>
          }
        />

        <ActiveUsersToolbar
          searchTerm={url.searchTerm}
          status={url.status}
          platform={url.platform}
          onSearchTermChange={url.setSearchTerm}
          onStatusChange={url.setStatus}
          onPlatformChange={url.setPlatform}
        />

        <div className={styles.layout}>
          <div className={styles.main}>
            <section aria-labelledby="active-users-kpi-heading">
              <h2 id="active-users-kpi-heading" className={styles.srOnly}>
                {t('sections.kpi')}
              </h2>
              <ActiveUsersSummarySection />
            </section>

            <section aria-labelledby="active-users-engagement-heading">
              <h2 id="active-users-engagement-heading" className={styles.srOnly}>
                {t('sections.engagement')}
              </h2>
              {props.engagementSection}
            </section>

            <section aria-labelledby="active-users-presence-heading">
              <h2 id="active-users-presence-heading" className={styles.sectionTitle}>
                {t('sections.presence')}
              </h2>
              <ActiveUsersTable
                page={url.page}
                onPageChange={url.setPage}
              />
            </section>
          </div>

          <aside className={styles.side} aria-label={t('sections.sidebar')}>
            <ActivityFeedPanel
              feedType={url.feedType}
              onFeedTypeChange={url.setFeedType}
            />
            {props.geoSection}
            <AlertsPanel {...(props.loadErrors?.alerts ? { loadError: props.loadErrors.alerts } : {})} />
          </aside>
        </div>
      </div>
    </ActiveUsersLiveProvider>
  );
}
