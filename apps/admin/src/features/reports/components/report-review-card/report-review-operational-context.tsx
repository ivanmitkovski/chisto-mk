'use client';

import { useEffect, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { motion } from 'framer-motion';
import { Button, Icon } from '@/components/ui';
import { useReadOnlyUnless } from '@/lib/auth/rbac/use-read-only-unless';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { parseSlaUrgency } from '../../utils/report-display';
import { isReportFinalStatus } from '../../utils/report-status';
import { useReportAssign } from '../../hooks/use-report-assign';
import { canAssignToOthers } from '../../utils/can-assign-to-others';
import { ReportModeratorAssignPicker } from '../report-moderator-assign-picker';
import type { EligibleModerator } from '../../data/eligible-moderators';
import type { ReportDetail } from '../../types';
import cardStyles from '../report-review-card.module.css';
import styles from './report-review-operational-context.module.css';

type ReportReviewOperationalContextProps = {
  report: ReportDetail;
  moderatorId?: string;
  moderatorDisplayName?: string;
  viewerRole?: string;
  eligibleModerators?: EligibleModerator[];
  onReportUpdated?: () => void;
  onReportChange?: (next: ReportDetail) => void;
};

export function ReportReviewOperationalContext({
  report,
  moderatorId,
  moderatorDisplayName,
  viewerRole,
  eligibleModerators = [],
  onReportUpdated,
  onReportChange,
}: ReportReviewOperationalContextProps) {
  const t = useTranslations('reports.operationalContext');
  const [isContextLegendOpen, setIsContextLegendOpen] = useState(false);
  const contextPanelRef = useRef<HTMLElement | null>(null);
  const readOnly = useReadOnlyUnless(ADMIN_PERMISSIONS['reports:moderate']);
  const isTerminalStatus = isReportFinalStatus(report.status);
  const slaUrgency = parseSlaUrgency(report.moderation.slaLabel);
  const slaModifier =
    slaUrgency === 'normal'
      ? ''
      : styles[`sla${slaUrgency.charAt(0).toUpperCase() + slaUrgency.slice(1)}` as 'slaUrgent' | 'slaCritical'];

  const assign = useReportAssign({
    report,
    currentModeratorId: moderatorId ?? null,
    ...(moderatorDisplayName ? { moderatorDisplayName } : {}),
    ...(onReportUpdated ? { onReportUpdated } : {}),
    onOptimistic: (next) => {
      onReportChange?.({
        ...report,
        status: next.status,
        moderation: { ...report.moderation, ...next.moderation },
      });
    },
    onRollback: () => onReportChange?.(report),
  });

  useEffect(() => {
    if (!isContextLegendOpen) return;
    const onPointerDown = (e: PointerEvent) => {
      const el = contextPanelRef.current;
      if (el && !el.contains(e.target as Node)) {
        setIsContextLegendOpen(false);
      }
    };
    document.addEventListener('pointerdown', onPointerDown);
    return () => document.removeEventListener('pointerdown', onPointerDown);
  }, [isContextLegendOpen]);

  const assigneeLabel =
    report.moderation.assignedModeratorName ??
    (report.moderation.assignedModeratorId ? t('assignedModeratorFallback') : t('unassigned'));

  const showAdminAssignPicker =
    canAssignToOthers(viewerRole) && !readOnly && !isTerminalStatus && eligibleModerators.length > 0;

  return (
    <motion.article
      ref={contextPanelRef}
      className={`${cardStyles.panel} ${cardStyles.railPanel} ${styles.contextPanel}`}
      whileHover={{ y: -2 }}
      transition={{ duration: 0.15 }}
    >
      <div className={styles.contextHeader}>
        <h3 className={cardStyles.railTitle}>{t('title')}</h3>
        <button
          type="button"
          className={styles.contextInfoBtn}
          onClick={() => setIsContextLegendOpen((v) => !v)}
          aria-expanded={isContextLegendOpen}
          aria-label={t('legendAria')}
          title={t('legendTitle')}
        >
          <Icon name="info" size={16} />
        </button>
      </div>
      {isContextLegendOpen ? (
        <div className={styles.contextLegend} role="region" aria-label={t('legendRegionAria')}>
          <div className={styles.contextLegendItem}>
            <span className={styles.contextLegendTerm}>{t('assignedModeratorTerm')}</span>
            <p className={styles.contextLegendDesc}>{t('assignedModeratorDesc')}</p>
          </div>
          <div className={styles.contextLegendItem}>
            <span className={styles.contextLegendTerm}>{t('slaTerm')}</span>
            <p className={styles.contextLegendDesc}>{t('slaDesc')}</p>
          </div>
          <div className={styles.contextLegendItem}>
            <span className={styles.contextLegendTerm}>{t('queueTerm')}</span>
            <p className={styles.contextLegendDesc}>{t('queueDesc')}</p>
          </div>
        </div>
      ) : null}
      <dl className={styles.contextList}>
        <div className={styles.contextItem}>
          <span className={styles.contextIcon} aria-hidden>
            <Icon name="users" size={16} />
          </span>
          <div className={styles.contextContent}>
            <dt>{t('assignedModerator')}</dt>
            <dd>{assigneeLabel}</dd>
          </div>
        </div>
        <div className={`${styles.contextItem} ${slaModifier ?? ''}`}>
          <span className={styles.contextIcon} aria-hidden>
            <Icon name="calendar" size={16} />
          </span>
          <div className={styles.contextContent}>
            <dt>{t('sla')}</dt>
            <dd>{report.moderation.slaLabel}</dd>
          </div>
        </div>
        <div className={styles.contextItem}>
          <span className={styles.contextIcon} aria-hidden>
            <Icon name="scroll-text" size={16} />
          </span>
          <div className={styles.contextContent}>
            <dt>{t('currentQueue')}</dt>
            <dd>{report.moderation.queueLabel}</dd>
          </div>
        </div>
      </dl>
      {showAdminAssignPicker ? (
        <ReportModeratorAssignPicker
          report={report}
          eligibleModerators={eligibleModerators}
          assign={assign}
        />
      ) : null}
      {!readOnly && !isTerminalStatus ? (
        <div className={styles.assignActions}>
          {!assign.isAssignedToMe ? (
            <Button
              variant="outline"
              size="sm"
              isLoading={assign.isAssigning}
              disabled={assign.isAssigning}
              onClick={() => void assign.assignToMe()}
            >
              {t('assignToMe')}
            </Button>
          ) : (
            <Button
              variant="outline"
              size="sm"
              isLoading={assign.isAssigning}
              disabled={assign.isAssigning}
              onClick={() => void assign.releaseAssignment()}
            >
              {t('releaseAssignment')}
            </Button>
          )}
          {assign.hasAssignee && !assign.isAssignedToMe ? (
            <>
              <Button
                variant="solid"
                size="sm"
                isLoading={assign.isAssigning}
                disabled={assign.isAssigning}
                onClick={() => void assign.assignToMe()}
              >
                {t('takeOverAssignment')}
              </Button>
              <p className={styles.assignHint}>
                {t('reassignHint', { name: report.moderation.assignedModeratorName ?? '' })}
              </p>
            </>
          ) : null}
        </div>
      ) : null}
    </motion.article>
  );
}
