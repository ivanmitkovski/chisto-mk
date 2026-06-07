'use client';

import { useTranslations } from 'next-intl';
import { Badge, Card, PageHeader, SectionState } from '@/components/ui';
import type { OperationsSnapshot } from '../data/operations-adapter';
import { OperationsActionsPanel } from './operations-actions-panel';
import { OperationsDeadLettersPanel } from './operations-dead-letters-panel';
import { OperationsRefreshBar } from './operations-refresh-bar';
import styles from './operations-workspace.module.css';

type PanelState = OperationsSnapshot[keyof OperationsSnapshot];

function OperationsCard({
  title,
  state,
  children,
}: {
  title: string;
  state: PanelState;
  children: React.ReactNode;
}) {
  const tCommon = useTranslations('common');

  return (
    <Card padding="md" className={styles.card}>
      <div className={styles.cardHeader}>
        <h2>{title}</h2>
        <Badge tone={state.status === 'ok' ? 'success' : 'danger'}>
          {state.status === 'ok' ? tCommon('live') : tCommon('error')}
        </Badge>
      </div>
      {state.status === 'ok' ? children : <SectionState variant="error" message={state.error} />}
      <p className={styles.updated}>{tCommon('updated', { time: new Date(state.updatedAt).toLocaleTimeString() })}</p>
    </Card>
  );
}

export function OperationsWorkspace({ snapshot }: { snapshot: OperationsSnapshot }) {
  const t = useTranslations('operations');

  return (
    <>
      <PageHeader title={t('pageTitle')} description={t('description')} />
      <OperationsActionsPanel />
      <OperationsRefreshBar />
      <div className={styles.linkRow}>
        <a href="/dashboard/comms/email-suppressions">{t('links.emailSuppressions')}</a>
        <a href="/dashboard/comms/webhook-logs">{t('links.webhookLogs')}</a>
      </div>
      <div className={styles.grid}>
        <OperationsCard title={t('cards.pushDelivery')} state={snapshot.pushStats}>
          {snapshot.pushStats.status === 'ok' ? (
            <dl className={styles.metrics}>
              <div><dt>{t('metrics.totalSends')}</dt><dd>{snapshot.pushStats.data.sendsTotal}</dd></div>
              <div><dt>{t('metrics.success')}</dt><dd>{snapshot.pushStats.data.sendsSuccess}</dd></div>
              <div><dt>{t('metrics.failures')}</dt><dd>{snapshot.pushStats.data.sendsFailure}</dd></div>
              <div><dt>{t('metrics.deadLetters')}</dt><dd>{snapshot.pushStats.data.deadLetterCount}</dd></div>
            </dl>
          ) : null}
        </OperationsCard>
        <OperationsCard title={t('cards.deliveryFunnel')} state={snapshot.deliveryReport}>
          {snapshot.deliveryReport.status === 'ok' ? (
            <dl className={styles.metrics}>
              <div><dt>{t('metrics.sent')}</dt><dd>{snapshot.deliveryReport.data.inbox?.notificationsSent ?? 0}</dd></div>
              <div><dt>{t('metrics.opened')}</dt><dd>{snapshot.deliveryReport.data.inbox?.notificationsOpened ?? 0}</dd></div>
              <div><dt>{t('metrics.openRate')}</dt><dd>{Math.round((snapshot.deliveryReport.data.inbox?.openRate ?? 0) * 100)}%</dd></div>
              <div><dt>{t('metrics.queueDepth')}</dt><dd>{snapshot.deliveryReport.data.queue?.depth ?? 0}</dd></div>
            </dl>
          ) : null}
        </OperationsCard>
        <OperationsCard title={t('cards.mapPipeline')} state={snapshot.mapHealth}>
          {snapshot.mapHealth.status === 'ok' ? (
            <>
              <dl className={styles.metrics}>
                <div><dt>{t('metrics.status')}</dt><dd>{snapshot.mapHealth.data.status}</dd></div>
                <div><dt>{t('metrics.outboxPending')}</dt><dd>{snapshot.mapHealth.data.outboxPending}</dd></div>
                <div><dt>{t('metrics.staleHotRows')}</dt><dd>{snapshot.mapHealth.data.staleHotProjectionRows}</dd></div>
              </dl>
              {snapshot.mapHealth.data.alerts.length > 0 ? (
                <p className={styles.alert}>{snapshot.mapHealth.data.alerts.join(', ')}</p>
              ) : null}
            </>
          ) : null}
        </OperationsCard>
        <OperationsCard title={t('cards.mapDeepProbe')} state={snapshot.mapDeep}>
          {snapshot.mapDeep.status === 'ok' ? (
            <>
              <dl className={styles.metrics}>
                <div><dt>{t('metrics.status')}</dt><dd>{snapshot.mapDeep.data.status}</dd></div>
                <div><dt>{t('metrics.latency')}</dt><dd>{snapshot.mapDeep.data.durationMs}ms</dd></div>
                <div><dt>{t('metrics.matches')}</dt><dd>{snapshot.mapDeep.data.matchCount}</dd></div>
                <div><dt>{t('metrics.path')}</dt><dd>{snapshot.mapDeep.data.queryPath}</dd></div>
              </dl>
              {snapshot.mapDeep.data.alerts.length > 0 ? (
                <p className={styles.alert}>{snapshot.mapDeep.data.alerts.join(', ')}</p>
              ) : null}
            </>
          ) : null}
        </OperationsCard>
        <OperationsCard title={t('cards.pushDeadLetters')} state={snapshot.deadLetters}>
          {snapshot.deadLetters.status === 'ok' ? (
            <OperationsDeadLettersPanel
              initialData={snapshot.deadLetters.data.data}
              initialMeta={snapshot.deadLetters.data.meta}
            />
          ) : null}
        </OperationsCard>
        <OperationsCard title={t('cards.feedDiagnostics')} state={snapshot.feedDiagnostics}>
          {snapshot.feedDiagnostics.status === 'ok' ? (
            <dl className={styles.metrics}>
              <div><dt>{t('metrics.reasonCodes')}</dt><dd>{snapshot.feedDiagnostics.data.reasonCodes.length}</dd></div>
              <div><dt>{t('metrics.rankDriftRows')}</dt><dd>{snapshot.feedDiagnostics.data.rankDriftSnapshot.length}</dd></div>
              <div><dt>{t('metrics.integrityDemotions')}</dt><dd>{snapshot.feedDiagnostics.data.recentIntegrityDemotions}</dd></div>
            </dl>
          ) : null}
        </OperationsCard>
        <OperationsCard title={t('cards.sideEffectsQueue')} state={snapshot.sideEffects}>
          {snapshot.sideEffects.status === 'ok' ? (
            <p>{t('metrics.pendingSideEffects', { count: snapshot.sideEffects.data.pendingCount })}</p>
          ) : null}
        </OperationsCard>
        <OperationsCard title={t('cards.emailSuppressions')} state={snapshot.emailSuppressions}>
          {snapshot.emailSuppressions.status === 'ok' ? (
            <p>{t('metrics.suppressedEmails', { count: snapshot.emailSuppressions.data.meta.total })}</p>
          ) : null}
        </OperationsCard>
        <OperationsCard title={t('cards.gdprAuditWatch')} state={snapshot.gdprAudit}>
          {snapshot.gdprAudit.status === 'ok' ? (
            <p>{t('metrics.gdprEntries', { count: snapshot.gdprAudit.data.meta.total })}</p>
          ) : null}
        </OperationsCard>
      </div>
    </>
  );
}
