'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import {
  MetricTile,
  MetricTileGrid,
  PageHeader,
  ProgressBar,
  Sparkline,
  StatusPill,
} from '@/components/ui';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import type { OperationsSnapshot } from '../data/operations-adapter';
import { useOperationsLive } from './operations-live-provider';
import { OperationsActionsPanel } from './operations-actions-panel';
import { OperationsDeadLettersPanel } from './operations-dead-letters-panel';
import { OperationsEmailDeadLettersPanel } from './operations-email-dead-letters-panel';
import { OperationsPanelCard } from './operations-panel-card';
import { OperationsRefreshBar } from './operations-refresh-bar';
import { OperationsStatusHeader } from './operations-status-header';
import styles from './operations-workspace.module.css';

function formatUptime(seconds: number): string {
  const days = Math.floor(seconds / 86_400);
  const hours = Math.floor((seconds % 86_400) / 3_600);
  const minutes = Math.floor((seconds % 3_600) / 60);
  if (days > 0) return `${days}d ${hours}h`;
  if (hours > 0) return `${hours}h ${minutes}m`;
  return `${minutes}m`;
}

export function OperationsWorkspace({ snapshot }: { snapshot: OperationsSnapshot }) {
  const t = useTranslations('operations');
  const tCommon = useTranslations('common');
  const locale = useAdminBcp47Locale();
  const { getSeries } = useOperationsLive();

  return (
    <>
      <PageHeader title={t('pageTitle')} description={t('description')} />
      <OperationsStatusHeader snapshot={snapshot} />
      <OperationsActionsPanel />
      <OperationsRefreshBar />
      <div className={styles.linkRow}>
        <Link href="/dashboard/comms/email-suppressions">{t('links.emailSuppressions')}</Link>
        <Link href="/dashboard/comms/webhook-logs">{t('links.webhookLogs')}</Link>
        <Link href="/dashboard/audit">{t('links.auditLog')}</Link>
      </div>

      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>{t('sections.delivery')}</h2>
        <div className={styles.grid}>
          <OperationsPanelCard panelKey="pushStats" title={t('cards.pushDelivery')} state={snapshot.pushStats}>
            {snapshot.pushStats.status === 'ok' ? (
              <>
                <MetricTileGrid>
                  <MetricTile label={t('metrics.totalSends')} value={snapshot.pushStats.data.sendsTotal} />
                  <MetricTile
                    label={t('metrics.success')}
                    value={snapshot.pushStats.data.sendsSuccess}
                    tone="success"
                    sparkline={<Sparkline data={getSeries('pushSendsSuccess')} ariaLabel={t('metrics.success')} />}
                  />
                  <MetricTile
                    label={t('metrics.failures')}
                    value={snapshot.pushStats.data.sendsFailure}
                    tone="danger"
                    sparkline={<Sparkline data={getSeries('pushSendsFailure')} ariaLabel={t('metrics.failures')} />}
                  />
                  <MetricTile label={t('metrics.revoked')} value={snapshot.pushStats.data.sendsRevoked} />
                  <MetricTile label={t('metrics.deadLetters')} value={snapshot.pushStats.data.deadLetterCount} />
                  <MetricTile
                    label={t('metrics.queueDepth')}
                    value={snapshot.pushStats.data.queueDepth}
                    sparkline={<Sparkline data={getSeries('pushQueueDepth')} ariaLabel={t('metrics.queueDepth')} />}
                  />
                  <MetricTile label={t('metrics.activeLeases')} value={snapshot.pushStats.data.activeLeases} />
                  <MetricTile label={t('metrics.tokenRevocations')} value={snapshot.pushStats.data.tokenRevocations} />
                  <MetricTile label={t('metrics.queueRetries')} value={snapshot.pushStats.data.queueRetries} />
                </MetricTileGrid>
                {Object.keys(snapshot.pushStats.data.sendsByType).length > 0 ? (
                  <ul className={styles.breakdownList}>
                    {Object.entries(snapshot.pushStats.data.sendsByType).slice(0, 5).map(([type, stats]) => (
                      <li key={type}>
                        <strong>{type}</strong> — {stats.success}/{stats.failure}/{stats.revoked}
                      </li>
                    ))}
                  </ul>
                ) : null}
              </>
            ) : null}
          </OperationsPanelCard>

          <OperationsPanelCard panelKey="deliveryReport" title={t('cards.deliveryFunnel')} state={snapshot.deliveryReport}>
            {snapshot.deliveryReport.status === 'ok' ? (
              <>
                <MetricTileGrid>
                  <MetricTile label={t('metrics.sent')} value={snapshot.deliveryReport.data.inbox.notificationsSent} />
                  <MetricTile label={t('metrics.opened')} value={snapshot.deliveryReport.data.inbox.notificationsOpened} />
                  <MetricTile
                    label={t('metrics.openRate')}
                    value={`${Math.round(snapshot.deliveryReport.data.inbox.openRate * 100)}%`}
                  />
                  <MetricTile label={t('metrics.queueDepth')} value={snapshot.deliveryReport.data.queue.depth} />
                  <MetricTile label={t('metrics.activeLeases')} value={snapshot.deliveryReport.data.queue.activeLeases} />
                  <MetricTile label={t('metrics.queueRetries')} value={snapshot.deliveryReport.data.queue.retries} />
                </MetricTileGrid>
                <ProgressBar
                  value={Math.round(snapshot.deliveryReport.data.inbox.openRate * 100)}
                  max={100}
                  label={t('metrics.openRate')}
                />
              </>
            ) : null}
          </OperationsPanelCard>

          <OperationsPanelCard panelKey="deadLetters" title={t('cards.pushDeadLetters')} state={snapshot.deadLetters}>
            {snapshot.deadLetters.status === 'ok' ? (
              <OperationsDeadLettersPanel
                initialData={snapshot.deadLetters.data.data}
                initialMeta={snapshot.deadLetters.data.meta}
              />
            ) : null}
          </OperationsPanelCard>

          <OperationsPanelCard panelKey="emailDeadLetters" title={t('cards.emailDeadLetters')} state={snapshot.emailDeadLetters}>
            {snapshot.emailDeadLetters.status === 'ok' ? (
              <OperationsEmailDeadLettersPanel
                initialData={snapshot.emailDeadLetters.data.data}
                initialMeta={snapshot.emailDeadLetters.data.meta}
              />
            ) : null}
          </OperationsPanelCard>
        </div>
      </section>

      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>{t('sections.pipeline')}</h2>
        <div className={styles.grid}>
          <OperationsPanelCard panelKey="mapHealth" title={t('cards.mapPipeline')} state={snapshot.mapHealth}>
            {snapshot.mapHealth.status === 'ok' ? (
              <>
                <MetricTileGrid>
                  <MetricTile label={t('metrics.status')} value={snapshot.mapHealth.data.status} />
                  <MetricTile
                    label={t('metrics.outboxPending')}
                    value={snapshot.mapHealth.data.outboxPending}
                    sparkline={<Sparkline data={getSeries('mapOutboxPending')} ariaLabel={t('metrics.outboxPending')} />}
                  />
                  <MetricTile label={t('metrics.staleHotRows')} value={snapshot.mapHealth.data.staleHotProjectionRows} />
                  <MetricTile
                    label={t('metrics.projectionEnabled')}
                    value={snapshot.mapHealth.data.mapUseProjection ? tCommon('yes') : tCommon('no')}
                  />
                </MetricTileGrid>
                {snapshot.mapHealth.data.alerts.length > 0 ? (
                  <p className={styles.alert}>{snapshot.mapHealth.data.alerts.join(', ')}</p>
                ) : null}
              </>
            ) : null}
          </OperationsPanelCard>

          <OperationsPanelCard panelKey="mapDeep" title={t('cards.mapDeepProbe')} state={snapshot.mapDeep}>
            {snapshot.mapDeep.status === 'ok' ? (
              <>
                <MetricTileGrid>
                  <MetricTile label={t('metrics.status')} value={snapshot.mapDeep.data.status} />
                  <MetricTile label={t('metrics.latency')} value={`${snapshot.mapDeep.data.durationMs}ms`} />
                  <MetricTile label={t('metrics.matches')} value={snapshot.mapDeep.data.matchCount} />
                  <MetricTile label={t('metrics.path')} value={snapshot.mapDeep.data.queryPath} />
                </MetricTileGrid>
                {snapshot.mapDeep.data.alerts.length > 0 ? (
                  <p className={styles.alert}>{snapshot.mapDeep.data.alerts.join(', ')}</p>
                ) : null}
              </>
            ) : null}
          </OperationsPanelCard>

          <OperationsPanelCard panelKey="feedDiagnostics" title={t('cards.feedDiagnostics')} state={snapshot.feedDiagnostics}>
            {snapshot.feedDiagnostics.status === 'ok' ? (
              <>
                <MetricTileGrid>
                  <MetricTile label={t('metrics.reasonCodes')} value={snapshot.feedDiagnostics.data.reasonCodes.length} />
                  <MetricTile label={t('metrics.rankDriftRows')} value={snapshot.feedDiagnostics.data.rankDriftSnapshot.length} />
                  <MetricTile label={t('metrics.integrityDemotions')} value={snapshot.feedDiagnostics.data.recentIntegrityDemotions} />
                </MetricTileGrid>
                {snapshot.feedDiagnostics.data.reasonCodes.length > 0 ? (
                  <ul className={styles.breakdownList}>
                    {snapshot.feedDiagnostics.data.reasonCodes.slice(0, 5).map((item) => (
                      <li key={item.code}>
                        <strong>{item.code}</strong> — {item.count}
                      </li>
                    ))}
                  </ul>
                ) : null}
                {snapshot.feedDiagnostics.data.rankDriftSnapshot.length > 0 ? (
                  <ul className={styles.breakdownList}>
                    {snapshot.feedDiagnostics.data.rankDriftSnapshot.slice(0, 3).map((item) => (
                      <li key={item.siteId}>
                        {item.siteId.slice(0, 8)}… · score {item.score.toFixed(2)}
                      </li>
                    ))}
                  </ul>
                ) : null}
              </>
            ) : null}
          </OperationsPanelCard>

          <OperationsPanelCard panelKey="sideEffects" title={t('cards.sideEffectsQueue')} state={snapshot.sideEffects}>
            {snapshot.sideEffects.status === 'ok' ? (
              <MetricTile label={t('metrics.pendingSideEffectsShort')} value={snapshot.sideEffects.data.pendingCount} />
            ) : null}
          </OperationsPanelCard>
        </div>
      </section>

      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>{t('sections.compliance')}</h2>
        <div className={styles.grid}>
          <OperationsPanelCard panelKey="gdprAudit" title={t('cards.gdprAuditWatch')} state={snapshot.gdprAudit}>
            {snapshot.gdprAudit.status === 'ok' ? (
              <>
                <p>{t('metrics.gdprEntries', { count: snapshot.gdprAudit.data.meta.total })}</p>
                {snapshot.gdprAudit.data.data.length > 0 ? (
                  <ul className={styles.breakdownList}>
                    {snapshot.gdprAudit.data.data.slice(0, 5).map((row) => (
                      <li key={row.id}>
                        <strong>{row.action}</strong>
                        {row.actorEmail ? ` · ${row.actorEmail}` : ''}
                        {' · '}
                        {formatAdminDateTime(row.createdAt, locale)}
                      </li>
                    ))}
                  </ul>
                ) : null}
              </>
            ) : null}
          </OperationsPanelCard>

          <OperationsPanelCard panelKey="emailSuppressions" title={t('cards.emailSuppressions')} state={snapshot.emailSuppressions}>
            {snapshot.emailSuppressions.status === 'ok' ? (
              <p>{t('metrics.suppressedEmails', { count: snapshot.emailSuppressions.data.meta.total })}</p>
            ) : null}
          </OperationsPanelCard>
        </div>
      </section>

      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>{t('sections.system')}</h2>
        <div className={styles.grid}>
          <OperationsPanelCard panelKey="readiness" title={t('cards.readiness')} state={snapshot.readiness}>
            {snapshot.readiness.status === 'ok' ? (
              <MetricTileGrid>
                <MetricTile label={t('metrics.status')} value={<StatusPill status={snapshot.readiness.data.status.toUpperCase()} />} />
                <MetricTile label={t('metrics.database')} value={snapshot.readiness.data.database} />
                <MetricTile label={t('metrics.redis')} value={snapshot.readiness.data.redis} />
                <MetricTile label={t('metrics.s3')} value={snapshot.readiness.data.s3} />
              </MetricTileGrid>
            ) : null}
          </OperationsPanelCard>

          <OperationsPanelCard panelKey="systemInfo" title={t('cards.systemInfo')} state={snapshot.systemInfo}>
            {snapshot.systemInfo.status === 'ok' ? (
              <MetricTileGrid>
                <MetricTile label={t('metrics.version')} value={snapshot.systemInfo.data.version} />
                <MetricTile label={t('metrics.gitSha')} value={snapshot.systemInfo.data.gitSha ?? '—'} />
                <MetricTile label={t('metrics.environment')} value={snapshot.systemInfo.data.nodeEnv} />
                <MetricTile label={t('metrics.region')} value={snapshot.systemInfo.data.region ?? '—'} />
                <MetricTile label={t('metrics.uptime')} value={formatUptime(snapshot.systemInfo.data.uptimeSeconds)} />
                <MetricTile
                  label={t('metrics.fcmEnabled')}
                  value={snapshot.systemInfo.data.fcmEnabled ? tCommon('yes') : tCommon('no')}
                />
              </MetricTileGrid>
            ) : null}
          </OperationsPanelCard>

          <OperationsPanelCard panelKey="workers" title={t('cards.workers')} state={snapshot.workers}>
            {snapshot.workers.status === 'ok' ? (
              <>
                <p className={styles.perReplicaNote}>{t('workers.perReplicaNote')}</p>
                <ul className={styles.workerList}>
                  {snapshot.workers.data.workers.map((worker) => (
                    <li key={worker.name} className={styles.workerItem}>
                      <div className={styles.workerHeader}>
                        <strong>{worker.name}</strong>
                        <StatusPill status={worker.stale ? 'STALE' : worker.running ? 'RUNNING' : 'STOPPED'} />
                      </div>
                      <span className={styles.workerMeta}>
                        {worker.lastRunAt
                          ? t('workers.lastRun', { time: formatAdminDateTime(worker.lastRunAt, locale) })
                          : t('workers.neverRun')}
                        {worker.lastError ? ` · ${worker.lastError}` : ''}
                      </span>
                    </li>
                  ))}
                </ul>
              </>
            ) : null}
          </OperationsPanelCard>
        </div>
      </section>
    </>
  );
}
