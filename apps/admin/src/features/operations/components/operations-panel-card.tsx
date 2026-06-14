'use client';

import { useLocale, useTranslations } from 'next-intl';
import type { ReactNode } from 'react';
import { Badge, Card, SectionState, StatusDot } from '@/components/ui';
import type { PanelState } from '../data/operations-adapter';
import type { OperationsPanelKey } from '../lib/operations-health';
import { derivePanelHealth, healthToBadgeTone } from '../lib/operations-health';
import { panelUpdatedAt } from './operations-status-header';
import styles from './operations-workspace.module.css';

export function OperationsPanelCard({
  panelKey,
  title,
  state,
  children,
  footer,
}: {
  panelKey: OperationsPanelKey;
  title: string;
  state: PanelState<unknown>;
  children: ReactNode;
  footer?: ReactNode;
}) {
  const t = useTranslations('operations');
  const tCommon = useTranslations('common');
  const locale = useLocale();
  const health = derivePanelHealth(panelKey, state);

  let body: ReactNode = children;
  if (state.status === 'forbidden') {
    body = <SectionState variant="empty" message={t('panels.insufficientPermission')} />;
  } else if (state.status === 'error') {
    body = <SectionState variant="error" message={state.error} />;
  }

  return (
    <Card padding="md" className={styles.card}>
      <div className={styles.cardHeader}>
        <h2>{title}</h2>
        <div className={styles.cardBadges}>
          <StatusDot status={health} label={t(`health.${health}`)} />
          <Badge tone={healthToBadgeTone(health)}>
            {state.status === 'ok' ? tCommon('live') : state.status === 'forbidden' ? t('panels.restricted') : tCommon('error')}
          </Badge>
        </div>
      </div>
      {body}
      {footer}
      <p className={styles.updated}>{tCommon('updated', { time: panelUpdatedAt(state, locale) })}</p>
    </Card>
  );
}
