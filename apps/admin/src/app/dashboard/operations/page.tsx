import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { Badge, Card, PageHeader, SectionState } from '@/components/ui';
import { getOperationsSnapshot } from '@/features/operations/data/operations-adapter';
import styles from './operations-page.module.css';

export default async function OperationsPage() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const snapshot = await getOperationsSnapshot();

  return (
    <AdminShell title="Operations" activeItem="operations" initialSidebarCollapsed={initialSidebarCollapsed}>
      <PageHeader
        title="Operations"
        description="Production health surfaces for push delivery, map pipeline, feed v2, side effects, and GDPR observability."
      />
      <div className={styles.grid}>
        <OperationsCard title="Push delivery" state={snapshot.pushStats}>
          {snapshot.pushStats.status === 'ok' ? (
            <dl className={styles.metrics}>
              <div><dt>Total sends</dt><dd>{snapshot.pushStats.data.sendsTotal}</dd></div>
              <div><dt>Success</dt><dd>{snapshot.pushStats.data.sendsSuccess}</dd></div>
              <div><dt>Failures</dt><dd>{snapshot.pushStats.data.sendsFailure}</dd></div>
              <div><dt>Dead letters</dt><dd>{snapshot.pushStats.data.deadLetterCount}</dd></div>
            </dl>
          ) : null}
        </OperationsCard>
        <OperationsCard title="Delivery funnel" state={snapshot.deliveryReport}>
          {snapshot.deliveryReport.status === 'ok' ? (
            <dl className={styles.metrics}>
              <div><dt>Sent</dt><dd>{snapshot.deliveryReport.data.inbox?.notificationsSent ?? 0}</dd></div>
              <div><dt>Opened</dt><dd>{snapshot.deliveryReport.data.inbox?.notificationsOpened ?? 0}</dd></div>
              <div><dt>Open rate</dt><dd>{Math.round((snapshot.deliveryReport.data.inbox?.openRate ?? 0) * 100)}%</dd></div>
              <div><dt>Queue depth</dt><dd>{snapshot.deliveryReport.data.queue?.depth ?? 0}</dd></div>
            </dl>
          ) : null}
        </OperationsCard>
        <OperationsCard title="Map pipeline" state={snapshot.mapHealth}>
          {snapshot.mapHealth.status === 'ok' ? (
            <>
              <dl className={styles.metrics}>
                <div><dt>Status</dt><dd>{snapshot.mapHealth.data.status}</dd></div>
                <div><dt>Outbox pending</dt><dd>{snapshot.mapHealth.data.outboxPending}</dd></div>
                <div><dt>Stale hot rows</dt><dd>{snapshot.mapHealth.data.staleHotProjectionRows}</dd></div>
              </dl>
              {snapshot.mapHealth.data.alerts.length > 0 ? <p className={styles.alert}>{snapshot.mapHealth.data.alerts.join(', ')}</p> : null}
            </>
          ) : null}
        </OperationsCard>
        <OperationsCard title="Map deep probe" state={snapshot.mapDeep}>
          {snapshot.mapDeep.status === 'ok' ? (
            <dl className={styles.metrics}>
              <div><dt>Status</dt><dd>{snapshot.mapDeep.data.status}</dd></div>
              <div><dt>Latency</dt><dd>{snapshot.mapDeep.data.durationMs}ms</dd></div>
              <div><dt>Matches</dt><dd>{snapshot.mapDeep.data.matchCount}</dd></div>
              <div><dt>Path</dt><dd>{snapshot.mapDeep.data.queryPath}</dd></div>
            </dl>
          ) : null}
        </OperationsCard>
        <OperationsCard title="Push dead letters" state={snapshot.deadLetters}>
          {snapshot.deadLetters.status === 'ok' ? (
            <p>{snapshot.deadLetters.data.meta?.total ?? snapshot.deadLetters.data.data?.length ?? 0} dead-letter entries currently visible.</p>
          ) : null}
        </OperationsCard>
        <OperationsCard title="GDPR audit watch" state={snapshot.gdprAudit}>
          {snapshot.gdprAudit.status === 'ok' ? (
            <p>{snapshot.gdprAudit.data.meta.total} recent user audit entries available for privacy review.</p>
          ) : null}
        </OperationsCard>
      </div>
    </AdminShell>
  );
}

function OperationsCard({
  title,
  state,
  children,
}: {
  title: string;
  state: { status: 'ok'; updatedAt: string } | { status: 'error'; error: string; updatedAt: string };
  children: React.ReactNode;
}) {
  return (
    <Card padding="md" className={styles.card}>
      <div className={styles.cardHeader}>
        <h2>{title}</h2>
        <Badge tone={state.status === 'ok' ? 'success' : 'danger'}>{state.status === 'ok' ? 'Live' : 'Error'}</Badge>
      </div>
      {state.status === 'ok' ? children : <SectionState variant="error" message={state.error} />}
      <p className={styles.updated}>Updated {new Date(state.updatedAt).toLocaleTimeString()}</p>
    </Card>
  );
}
