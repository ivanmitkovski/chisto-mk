'use client';

import Image from 'next/image';
import { useTranslations } from 'next-intl';
import { motion } from 'framer-motion';
import { Icon } from '@/components/ui';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import { isReportFinalStatus } from '../../utils/report-status';
import type { ReportDetail, ReportEvidence } from '../../types';
import type { ContextDetailKind } from '../context-detail-modal';
import cardStyles from '../report-review-card.module.css';
import styles from './report-review-summary-panel.module.css';

type ReportReviewSummaryPanelProps = {
  report: ReportDetail;
  photoEvidence: ReportEvidence[];
  activePhoto: ReportEvidence | null;
  fullPage?: boolean;
  onOpenLightbox: (photoId?: string) => void;
  onOpenContextDetail: (kind: ContextDetailKind) => void;
};

export function ReportReviewSummaryPanel({
  report,
  photoEvidence,
  activePhoto,
  fullPage = false,
  onOpenLightbox,
  onOpenContextDetail,
}: ReportReviewSummaryPanelProps) {
  const t = useTranslations('reports.evidence');
  const locale = useAdminBcp47Locale();
  const isTerminalStatus = isReportFinalStatus(report.status);

  return (
    <motion.article className={cardStyles.panel} whileHover={{ y: -2 }} transition={{ duration: 0.15 }} aria-label={t('summaryAria')}>
      <div className={`${styles.image} ${fullPage ? styles.fullPageImage : ''}`}>
        {activePhoto?.previewUrl ? (
          <button
            type="button"
            className={styles.imagePreviewButton}
            aria-label={t('openFullscreenAria')}
            onClick={() => onOpenLightbox()}
          >
            <Image
              src={activePhoto.previewUrl}
              alt={activePhoto.previewAlt ?? activePhoto.label}
              className={styles.imagePhoto}
              loading="lazy"
              fill
              sizes="(min-width: 768px) 50vw, 100vw"
            />
          </button>
        ) : null}
        <div className={styles.imageOverlay}>
          <span className={styles.reportNumber}>{t('reportNumber', { reportNumber: report.reportNumber })}</span>
          <span className={styles.location}>
            <Icon name="location" size={14} />
            {report.location}
          </span>
        </div>
      </div>
      {photoEvidence.length > 0 ? (
        <div className={styles.photoStrip} role="tablist" aria-label={t('thumbnailsAria')}>
          {photoEvidence.map((item) => (
            <button
              key={item.id}
              type="button"
              role="tab"
              aria-selected={item.id === activePhoto?.id}
              className={`${styles.photoThumb} ${item.id === activePhoto?.id ? styles.photoThumbActive : ''}`}
              onClick={() => onOpenLightbox(item.id)}
            >
              {item.previewUrl ? (
                <Image src={item.previewUrl} alt={item.previewAlt ?? item.label} loading="lazy" width={86} height={64} />
              ) : null}
            </button>
          ))}
        </div>
      ) : null}
      <div className={styles.body}>
        {report.description.trim().length > 0 ? <p className={styles.reportText}>{report.description}</p> : null}
        <div className={styles.metaGrid}>
          <button
            type="button"
            className={styles.metaGridItem}
            disabled={isTerminalStatus}
            onClick={() => onOpenContextDetail('submitted')}
            aria-label={t('viewSubmittedAria')}
          >
            <span className={styles.metaIcon} aria-hidden>
              <Icon name="calendar" size={14} />
            </span>
            <div>
              <span className={styles.metaLabel}>{t('metaSubmitted')}</span>
              <span className={styles.metaValue}>{formatAdminDateTime(report.submittedAt, locale)}</span>
            </div>
          </button>
          <button
            type="button"
            className={styles.metaGridItem}
            disabled={isTerminalStatus}
            onClick={() => onOpenContextDetail('reporter')}
            aria-label={t('viewReporterAria')}
          >
            <span className={styles.metaIcon} aria-hidden>
              <Icon name="user" size={14} />
            </span>
            <div>
              <span className={styles.metaLabel}>{t('metaReporter')}</span>
              <span className={styles.metaValue}>{report.reporterAlias}</span>
            </div>
          </button>
          {report.cleanupEffortLabel ? (
            <div className={styles.metaGridItem} aria-label={t('cleanupEffortAria')}>
              <span className={styles.metaIcon} aria-hidden>
                <Icon name="users" size={14} />
              </span>
              <div>
                <span className={styles.metaLabel}>{t('metaCleanupEffort')}</span>
                <span className={styles.metaValue}>{report.cleanupEffortLabel}</span>
              </div>
            </div>
          ) : null}
          {report.coReporters.length > 0 && !report.isPotentialDuplicate ? (
            <button
              type="button"
              className={styles.metaGridItem}
              disabled={isTerminalStatus}
              onClick={() => onOpenContextDetail('co-reporters')}
              aria-label={t('viewCoReportersAria')}
            >
              <span className={styles.metaIcon} aria-hidden>
                <Icon name="users" size={14} />
              </span>
              <div>
                <span className={styles.metaLabel}>{t('metaCoReporters')}</span>
                <span className={styles.metaValue}>{report.coReporters.join(', ')}</span>
              </div>
            </button>
          ) : null}
          <button
            type="button"
            className={styles.metaGridItem}
            disabled={isTerminalStatus}
            onClick={() => onOpenContextDetail('trust-tier')}
            aria-label={t('viewTrustTierAria')}
          >
            <span className={styles.metaIcon} aria-hidden>
              <Icon name="shield" size={14} />
            </span>
            <div>
              <span className={styles.metaLabel}>{t('metaTrustTier')}</span>
              <span className={styles.metaValue}>{report.reporterTrust}</span>
            </div>
          </button>
          <button
            type="button"
            className={styles.metaGridItem}
            disabled={isTerminalStatus}
            onClick={() => onOpenContextDetail('queue')}
            aria-label={t('viewQueueAria')}
          >
            <span className={styles.metaIcon} aria-hidden>
              <Icon name="scroll-text" size={14} />
            </span>
            <div>
              <span className={styles.metaLabel}>{t('metaQueue')}</span>
              <span className={styles.metaValue}>{report.moderation.queueLabel}</span>
            </div>
          </button>
        </div>
      </div>
    </motion.article>
  );
}
