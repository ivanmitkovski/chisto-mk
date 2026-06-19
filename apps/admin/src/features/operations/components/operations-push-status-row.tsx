'use client';

import { useTranslations } from 'next-intl';
import { Badge, StatusDot } from '@/components/ui';
import type { OperationsSnapshot } from '../data/operations-snapshot';
import styles from './operations-workspace.module.css';

type PushDiagnosticsData = OperationsSnapshot['pushDiagnostics'] extends {
  status: 'ok';
  data: infer T;
}
  ? T
  : never;

type PushHealthData = OperationsSnapshot['pushHealth'] extends { status: 'ok'; data: infer T }
  ? T
  : never;

export function OperationsPushStatusRow({
  pushDiagnostics,
  pushHealth,
}: {
  pushDiagnostics: PushDiagnosticsData | null;
  pushHealth: PushHealthData | null;
}) {
  const t = useTranslations('operations');

  if (!pushDiagnostics && !pushHealth) {
    return null;
  }

  const fcmReady = pushDiagnostics?.fcmReady ?? pushHealth?.fcmReady ?? false;
  const fcmEnabled = pushDiagnostics?.fcmEnabled ?? pushHealth?.fcmEnabled ?? false;
  const credentialStatus = pushDiagnostics?.credentialStatus ?? pushHealth?.credentialStatus ?? 'missing';
  const workerStale = pushDiagnostics?.workerStatus?.stale ?? pushHealth?.worker?.stale ?? false;
  const remediation = pushDiagnostics?.remediation ?? null;

  return (
    <div className={styles.pushStatusBlock}>
      <div className={styles.cardBadges}>
        <Badge tone={fcmReady ? 'success' : fcmEnabled ? 'danger' : 'neutral'}>
          {fcmReady ? t('pushStatus.fcmReady') : fcmEnabled ? t('pushStatus.fcmNotReady') : t('pushStatus.fcmDisabled')}
        </Badge>
        {pushDiagnostics?.projectId ?? pushHealth?.projectId ? (
          <Badge tone="neutral">{pushDiagnostics?.projectId ?? pushHealth?.projectId}</Badge>
        ) : null}
        <Badge tone={workerStale ? 'warning' : 'success'}>
          {workerStale ? t('pushStatus.workerStale') : t('pushStatus.workerOk')}
        </Badge>
        <Badge tone={credentialStatus === 'valid' ? 'success' : 'danger'}>
          {t('pushStatus.credential', { status: credentialStatus })}
        </Badge>
        {pushDiagnostics ? (
          <Badge tone="neutral">{t('pushStatus.deviceTokens', { count: pushDiagnostics.registeredDeviceTokens })}</Badge>
        ) : null}
      </div>
      {remediation ? (
        <div className={styles.remediationBanner} role="status">
          <StatusDot status="warn" label={t('health.warn')} />
          <p>{remediation}</p>
        </div>
      ) : null}
    </div>
  );
}
