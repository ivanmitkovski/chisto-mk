'use client';

import { KeyboardEvent as ReactKeyboardEvent, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { motion } from 'framer-motion';
import { Card } from '@/components/ui';
import { useReadOnlyUnless } from '@/lib/auth/rbac/use-read-only-unless';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { useRejectionReasonOptions } from '../hooks/use-rejection-reason-options';
import { formatDateTime } from '../utils/report-display';
import { useReportReview } from '../hooks/use-report-review';
import { useReportPhotoGallery } from '../hooks/use-report-photo-gallery';
import { useReportReviewConfirm } from '../hooks/use-report-review-confirm';
import { ActionConfirmModal } from './action-confirm-modal';
import { ReportReviewEvidencePanel } from './report-review-card/report-review-evidence-panel';
import { ReportReviewModerationActionRail } from './report-review-card/report-review-moderation-action-rail';
import { ReportReviewTimelinePanel } from './report-review-timeline-panel';
import { ContextDetailModal, type ContextDetailKind } from './context-detail-modal';
import { LocationMapCard } from './location-map-card';
import { ReportReviewHeader } from './report-review-card/report-review-header';
import { ReportReviewSummaryPanel } from './report-review-card/report-review-summary-panel';
import { ReportReviewOperationalContext } from './report-review-card/report-review-operational-context';
import { ReportPhotoLightbox } from './report-review-card/report-photo-lightbox';
import { ReportDetail } from '../types';
import { isReportFinalStatus } from '../utils/report-status';
import type { ReportPillClassNames } from '../utils/report-pills';
import type { EligibleModerator } from '../data/eligible-moderators';
import styles from './report-review-card.module.css';

const pillStyles = styles as ReportPillClassNames;

type ReportReviewCardProps = {
  report: ReportDetail;
  onReportUpdated?: () => void;
  hideHeader?: boolean;
  fullPage?: boolean;
  moderatorId?: string;
  moderatorDisplayName?: string;
  viewerRole?: string;
  eligibleModerators?: EligibleModerator[];
  otherViewersCount?: number;
};

export function ReportReviewCard({
  report,
  onReportUpdated,
  hideHeader = false,
  fullPage = false,
  moderatorId,
  moderatorDisplayName,
  viewerRole,
  eligibleModerators = [],
  otherViewersCount = 0,
}: ReportReviewCardProps) {
  const tCommon = useTranslations('common');
  const tRejection = useTranslations('reports.rejectionReasons');
  const rejectionReasonOptions = useRejectionReasonOptions();

  const { report: currentReport, setReport, isUpdating, setInReview, approveReport, rejectReport } = useReportReview(
    report,
    {
      ...(onReportUpdated ? { onReportUpdated } : {}),
      ...(moderatorDisplayName ? { moderatorDisplayName } : {}),
    },
  );

  const actionButtonsRef = useRef<Array<HTMLButtonElement | null>>([]);
  const [contextDetailModal, setContextDetailModal] = useState<ContextDetailKind | null>(null);

  const {
    photoEvidence,
    activePhoto,
    activePhotoIndex,
    setActivePhotoId,
    isLightboxOpen,
    setIsLightboxOpen,
    openLightbox,
    showPreviousPhoto,
    showNextPhoto,
    filmstripRef,
    thumbRefs,
  } = useReportPhotoGallery({ evidence: currentReport.evidence });

  const {
    pendingAction,
    setPendingAction,
    rejectionReason,
    rejectionNotes,
    rejectionReasonError,
    setRejectionReason,
    setRejectionNotes,
    setRejectionReasonError,
    closeConfirmModal,
    confirmAction,
    modalTitle,
    modalDescription,
    confirmLabel,
  } = useReportReviewConfirm({ isUpdating, setInReview, approveReport, rejectReport, otherViewersCount });

  const isTerminalStatus = isReportFinalStatus(currentReport.status);
  const readOnly = useReadOnlyUnless(ADMIN_PERMISSIONS['reports:moderate']);
  const isSetInReviewDisabled =
    readOnly || isTerminalStatus || currentReport.status === 'IN_REVIEW' || isUpdating;
  const isApproveDisabled = readOnly || isTerminalStatus || isUpdating;
  const isRejectDisabled = readOnly || isTerminalStatus || isUpdating;
  const allActionsDisabled = isSetInReviewDisabled && isApproveDisabled && isRejectDisabled;
  const actionDisabledFlags = [isSetInReviewDisabled, isApproveDisabled, isRejectDisabled];

  function onActionRailKeyDown(event: ReactKeyboardEvent<HTMLDivElement>) {
    if (allActionsDisabled) return;

    const key = event.key;
    if (key !== 'ArrowDown' && key !== 'ArrowUp' && key !== 'Home' && key !== 'End') {
      return;
    }

    const activeIndex = actionButtonsRef.current.findIndex((button) => button === document.activeElement);
    const enabledIndices = actionDisabledFlags.map((disabled, i) => (disabled ? -1 : i)).filter((i) => i >= 0);

    if (enabledIndices.length === 0) return;

    if (activeIndex === -1 && key !== 'Home' && key !== 'End') {
      return;
    }

    event.preventDefault();

    if (key === 'Home') {
      actionButtonsRef.current[enabledIndices[0]]?.focus();
      return;
    }

    if (key === 'End') {
      actionButtonsRef.current[enabledIndices[enabledIndices.length - 1]]?.focus();
      return;
    }

    const currentEnabledIndex = enabledIndices.indexOf(activeIndex);
    if (currentEnabledIndex === -1) {
      actionButtonsRef.current[enabledIndices[0]]?.focus();
      return;
    }

    const step = key === 'ArrowDown' ? 1 : -1;
    const nextEnabledIndex = (currentEnabledIndex + step + enabledIndices.length) % enabledIndices.length;
    actionButtonsRef.current[enabledIndices[nextEnabledIndex]]?.focus();
  }

  return (
    <motion.div initial={{ opacity: 0, y: 14 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.28, ease: 'easeOut' }}>
      <Card className={`${styles.card} ${fullPage ? styles.fullPage : ''}`}>
        {!hideHeader ? <ReportReviewHeader report={currentReport} pillStyles={pillStyles} /> : null}
        <div className={styles.grid}>
          <section className={styles.mainColumn}>
            <ReportReviewSummaryPanel
              report={currentReport}
              photoEvidence={photoEvidence}
              activePhoto={activePhoto}
              fullPage={fullPage}
              onOpenLightbox={openLightbox}
              onOpenContextDetail={setContextDetailModal}
            />
            <ReportReviewEvidencePanel
              evidence={currentReport.evidence}
              onOpenImageEvidence={(evidenceId) => openLightbox(evidenceId)}
            />
            <ReportReviewTimelinePanel entries={currentReport.timeline} />
          </section>

          <aside className={styles.actionRail}>
            <ReportReviewModerationActionRail
              currentReport={currentReport}
              pillStyles={pillStyles}
              allActionsDisabled={allActionsDisabled}
              isUpdating={isUpdating}
              isSetInReviewDisabled={isSetInReviewDisabled}
              isApproveDisabled={isApproveDisabled}
              isRejectDisabled={isRejectDisabled}
              actionButtonsRef={actionButtonsRef}
              onActionRailKeyDown={onActionRailKeyDown}
              onSelectAction={setPendingAction}
            />
            <ReportReviewOperationalContext
              report={currentReport}
              eligibleModerators={eligibleModerators}
              {...(viewerRole ? { viewerRole } : {})}
              {...(moderatorId ? { moderatorId } : {})}
              {...(moderatorDisplayName ? { moderatorDisplayName } : {})}
              {...(onReportUpdated ? { onReportUpdated } : {})}
              onReportChange={setReport}
            />
            <motion.article className={`${styles.panel} ${styles.railPanel}`} whileHover={{ y: -2 }} transition={{ duration: 0.15 }}>
              <LocationMapCard mapPin={currentReport.mapPin} locationLabel={currentReport.mapPin.label || currentReport.location} />
            </motion.article>
          </aside>
        </div>
      </Card>

      <ReportPhotoLightbox
        isOpen={isLightboxOpen}
        photoEvidence={photoEvidence}
        activePhoto={activePhoto}
        activePhotoIndex={activePhotoIndex}
        filmstripRef={filmstripRef}
        thumbRefs={thumbRefs}
        onClose={() => setIsLightboxOpen(false)}
        onSelectPhoto={setActivePhotoId}
        onShowPrevious={showPreviousPhoto}
        onShowNext={showNextPhoto}
      />

      <ActionConfirmModal
        isOpen={pendingAction !== null}
        title={modalTitle}
        description={modalDescription}
        confirmLabel={confirmLabel}
        confirmTone={pendingAction === 'reject' ? 'danger' : 'default'}
        requireReason={pendingAction === 'reject'}
        reasonOptions={rejectionReasonOptions}
        selectedReason={rejectionReason}
        reasonError={rejectionReasonError}
        notesValue={rejectionNotes}
        reasonLabel={tRejection('label')}
        notesLabel={tRejection('notesLabel')}
        notesPlaceholder={tRejection('notesPlaceholder')}
        cancelLabel={tCommon('cancel')}
        onSelectedReasonChange={(value) => {
          setRejectionReason(value);
          if (rejectionReasonError) {
            setRejectionReasonError(null);
          }
        }}
        onNotesChange={setRejectionNotes}
        isConfirming={isUpdating}
        onCancel={closeConfirmModal}
        onConfirm={confirmAction}
      />

      <ContextDetailModal
        isOpen={contextDetailModal !== null}
        kind={contextDetailModal}
        value={
          contextDetailModal === 'submitted'
            ? formatDateTime(currentReport.submittedAt)
            : contextDetailModal === 'reporter'
              ? currentReport.reporterAlias
              : contextDetailModal === 'co-reporters'
                ? currentReport.coReporters.join(', ')
                : contextDetailModal === 'trust-tier'
                  ? currentReport.reporterTrust
                  : contextDetailModal === 'queue'
                    ? currentReport.moderation.queueLabel
                    : ''
        }
        onClose={() => setContextDetailModal(null)}
      />
    </motion.div>
  );
}
