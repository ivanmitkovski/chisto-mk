import { Card, PanelSkeleton } from '@/components/ui';
import { getEventsStats } from '../data/events-adapter';
import { EventsWorkspaceStatsMotion } from './events-workspace-stats-motion';
import styles from './events-workspace.module.css';

export function EventsStatsFallback() {
  return <div className={styles.statsBar} aria-busy="true" aria-hidden />;
}

export async function EventsStatsSection({
  moderationQueueHref,
}: {
  moderationQueueHref: string;
}) {
  const stats = await getEventsStats();
  return (
    <EventsWorkspaceStatsMotion
      stats={stats}
      totalParticipants={stats.totalParticipants}
      moderationQueueHref={moderationQueueHref}
    />
  );
}

export function EventsStatsSectionCardFallback() {
  return (
    <Card padding="md">
      <PanelSkeleton lines={4} />
    </Card>
  );
}
