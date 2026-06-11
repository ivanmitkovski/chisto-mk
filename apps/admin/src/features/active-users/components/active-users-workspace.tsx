'use client';

import type {
  ActiveUserRow,
  ActiveUsersSummary,
  AdminAlertRule,
  EngagementAnalytics,
  GeoCluster,
  RealtimeAnalytics,
} from '../data/active-users.types';
import { ActiveUsersSseBridge } from './active-users-sse-bridge';
import { ActiveUsersSummaryCards } from './active-users-summary';
import { ActiveUsersTable } from './active-users-table';
import { ActivityFeedPanel } from './activity-feed-panel';
import { ActiveUsersGeoMap } from './active-users-geo-map-client';
import { AlertsPanel } from './alerts-panel';
import { EngagementCharts } from './engagement-charts';
import { ActiveUsersLiveProvider } from '../hooks/use-active-users-live';
import styles from './active-users-workspace.module.css';

export function ActiveUsersWorkspace({
  initialSummary,
  initialRows,
  engagement,
  realtime,
  geoClusters,
  alertRules,
}: {
  initialSummary: ActiveUsersSummary | null;
  initialRows: ActiveUserRow[];
  engagement: EngagementAnalytics;
  realtime: RealtimeAnalytics;
  geoClusters: GeoCluster[];
  alertRules: AdminAlertRule[];
}) {
  return (
    <ActiveUsersLiveProvider initialSummary={initialSummary}>
      <ActiveUsersSseBridge />
      <div className={styles.layout}>
        <div className={styles.main}>
          <ActiveUsersSummaryCards />
          <EngagementCharts engagement={engagement} realtime={realtime} />
          <ActiveUsersTable rows={initialRows} />
        </div>
        <aside className={styles.side}>
          <ActivityFeedPanel />
          <ActiveUsersGeoMap clusters={geoClusters} />
          <AlertsPanel rules={alertRules} />
        </aside>
      </div>
    </ActiveUsersLiveProvider>
  );
}
