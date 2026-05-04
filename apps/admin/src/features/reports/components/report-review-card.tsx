'use client';

import Image from 'next/image';
import Link from 'next/link';
import { KeyboardEvent as ReactKeyboardEvent, useEffect, useMemo, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { AnimatePresence, motion } from 'framer-motion';
import { Card, Icon, Snack } from '@/components/ui';
import { rejectionReasonOptions } from '../constants/rejection-reasons';
import { formatDateTime, parseSlaUrgency } from '../utils/report-display';
import { useReportReview } from '../hooks/use-report-review';
import { ActionConfirmModal } from './action-confirm-modal';
import { ReportReviewEvidencePanel } from './report-review-card/report-review-evidence-panel';
import { ReportReviewModerationActionRail } from './report-review-card/report-review-moderation-action-rail';
import { ReportReviewTimelinePanel } from './report-review-timeline-panel';
import { ContextDetailModal, type ContextDetailKind } from './context-detail-modal';
import { LocationMapCard } from './location-map-card';
import { ReportDetail } from '../types';
import { formatReportStatus, isReportFinalStatus, statusIconName } from '../utils/report-status';
import type { ReportPillClassNames } from '../utils/report-pills';
import { reportPriorityPillClass, reportStatusPillClass } from '../utils/report-pills';
import styles from './report-review-card.module.css';

const pillStyles = styles as ReportPillClassNames;

type ReportReviewCardProps = {
  report: ReportDetail;
  onReportUpdated?: () => void;
  /** When true, hide the header (kicker, title, pills) — used when parent provides its own header */
  hideHeader?: boolean;
  /** When true, use full-page layout (no card border, full-width grid, larger image hero) */
  fullPage?: boolean;
};

export function ReportReviewCard({ report, onReportUpdated, hideHeader = false, fullPage = false }: ReportReviewCardProps) {
  const { report: currentReport, isUpdating, snack, setInReview, approveReport, rejectReport, clearSnack } = useReportReview(
    report,
    onReportUpdated ? { onReportUpdated } : undefined,
  );
  const actionButtonsRef = useRef<Array<HTMLButtonElement | null>>([]);
  const [pendingAction, setPendingAction] = useState<'set-in-review' | 'approve' | 'reject' | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [rejectionNotes, setRejectionNotes] = useState('');
  const [rejectionReasonError, setRejectionReasonError] = useState<string | null>(null);
  const [activePhotoId, setActivePhotoId] = useState<string | null>(null);
  const [isLightboxOpen, setIsLightboxOpen] = useState(false);
  const [isContextLegendOpen, setIsContextLegendOpen] = useState(false);
  const [contextDetailModal, setContextDetailModal] = useState<ContextDetailKind | null>(null);
  const contextPanelRef = useRef<HTMLElement | null>(null);
  const filmstripRef = useRef<HTMLDivElement | null>(null);
  const thumbRefs = useRef<Map<number, HTMLButtonElement | null>>(new Map());

  const photoEvidence = useMemo(
    () => currentReport.evidence.filter((item) => item.kind === 'image' && item.previewUrl),
    [currentReport.evidence],
  );

  useEffect(() => {
    if (photoEvidence.length === 0) {
      setActivePhotoId(null);
      return;
    }

    const hasActive = photoEvidence.some((item) => item.id === activePhotoId);
    if (!hasActive) {
      setActivePhotoId(photoEvidence[0].id);
    }
  }, [activePhotoId, photoEvidence]);

  const activePhoto = photoEvidence.find((item) => item.id === activePhotoId) ?? photoEvidence[0] ?? null;
  const activePhotoIndex = photoEvidence.findIndex((item) => item.id === activePhoto?.id);

  const slaUrgency = parseSlaUrgency(currentReport.moderation.slaLabel);
  const isTerminalStatus = isReportFinalStatus(currentReport.status);
  const isSetInReviewDisabled =
    isTerminalStatus || currentReport.status === 'IN_REVIEW' || isUpdating;
  const isApproveDisabled = isTerminalStatus || isUpdating;
  const isRejectDisabled = isTerminalStatus || isUpdating;
  const allActionsDisabled = isSetInReviewDisabled && isApproveDisabled && isRejectDisabled;

  function showPreviousPhoto() {
    if (photoEvidence.length < 2 || activePhotoIndex === -1) {
      return;
    }

    const nextIndex = (activePhotoIndex - 1 + photoEvidence.length) % photoEvidence.length;
    setActivePhotoId(photoEvidence[nextIndex].id);
  }

  function showNextPhoto() {
    if (photoEvidence.length < 2 || activePhotoIndex === -1) {
      return;
    }

    const nextIndex = (activePhotoIndex + 1) % photoEvidence.length;
    setActivePhotoId(photoEvidence[nextIndex].id);
  }

  const actionDisabledFlags = [isSetInReviewDisabled, isApproveDisabled, isRejectDisabled];

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

  function onActionRailKeyDown(event: ReactKeyboardEvent<HTMLDivElement>) {
    if (allActionsDisabled) return;

    const key = event.key;
    if (key !== 'ArrowDown' && key !== 'ArrowUp' && key !== 'Home' && key !== 'End') {
      return;
    }

    const activeIndex = actionButtonsRef.current.findIndex((button) => button === document.activeElement);
    const enabledIndices = actionDisabledFlags
      .map((disabled, i) => (disabled ? -1 : i))
      .filter((i) => i >= 0);

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
    const nextEnabledIndex =
      (currentEnabledIndex + step + enabledIndices.length) % enabledIndices.length;
    actionButtonsRef.current[enabledIndices[nextEnabledIndex]]?.focus();
  }

  function closeConfirmModal() {
    if (isUpdating) {
      return;
    }

    setPendingAction(null);
    setRejectionReasonError(null);
    setRejectionReason('');
    setRejectionNotes('');
  }

  async function confirmAction() {
    if (!pendingAction) {
      return;
    }

    if (pendingAction === 'reject') {
      if (!rejectionReason) {
        setRejectionReasonError('Please select a rejection reason.');
        return;
      }

      setRejectionReasonError(null);
      const composedReason = rejectionNotes.trim()
        ? `${rejectionReason}. Notes: ${rejectionNotes.trim()}`
        : rejectionReason;
      const ok = await rejectReport(composedReason);
      if (ok) closeConfirmModal();
      return;
    }

    if (pendingAction === 'approve') {
      const ok = await approveReport();
      if (ok) closeConfirmModal();
      return;
    }

    const ok = await setInReview();
    if (ok) closeConfirmModal();
  }

  const modalTitle =
    pendingAction === 'approve'
      ? 'Confirm approval'
      : pendingAction === 'reject'
        ? 'Confirm rejection'
        : 'Confirm status update';
  const modalDescription =
    pendingAction === 'approve'
      ? 'Approve this report and move it to the approved lifecycle state?'
      : pendingAction === 'reject'
        ? 'Reject this report. A rejection reason is required for moderation traceability.'
        : 'Move this report into in-review status for deeper moderation checks?';
  const confirmLabel =
    pendingAction === 'approve' ? 'Approve report' : pendingAction === 'reject' ? 'Reject report' : 'Set in review';

  useEffect(() => {
    const el = thumbRefs.current.get(activePhotoIndex);
    if (el && filmstripRef.current) {
      el.scrollIntoView({ block: 'nearest', inline: 'center', behavior: 'smooth' });
    }
  }, [activePhotoIndex, isLightboxOpen]);

  useEffect(() => {
    if (!isLightboxOpen) {
      return;
    }

    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        setIsLightboxOpen(false);
        return;
      }

      if (event.key === 'ArrowLeft') {
        event.preventDefault();
        showPreviousPhoto();
        return;
      }

      if (event.key === 'ArrowRight') {
        event.preventDefault();
        showNextPhoto();
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return () => {
      document.body.style.overflow = previousOverflow;
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [isLightboxOpen, activePhotoIndex, photoEvidence]);

  return (
    <motion.div
      initial={{ opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.28, ease: 'easeOut' }}
    >
      <Card className={`${styles.card} ${fullPage ? styles.fullPage : ''}`}>
        {!hideHeader && (
          <header className={styles.header}>
            <div>
              <p className={styles.kicker}>Moderation workspace</p>
              <h2 className={styles.title}>{currentReport.title}</h2>
            </div>
            <div className={styles.headerPills}>
              <span className={reportStatusPillClass(currentReport.status, pillStyles)}>
                <Icon name={statusIconName(currentReport.status)} size={12} />
                {formatReportStatus(currentReport.status)}
              </span>
              <span className={reportPriorityPillClass(currentReport.priority, pillStyles)}>
                {currentReport.priority} priority
              </span>
            </div>
          </header>
        )}
        {currentReport.isPotentialDuplicate ? (
          <div className={styles.duplicateNotice} role="status">
            <p className={styles.duplicateNoticeText}>
              {currentReport.potentialDuplicateOfReportNumber
                ? `This report may be a duplicate of ${currentReport.potentialDuplicateOfReportNumber}.`
                : 'This report may be a duplicate of another.'}
              {currentReport.coReporters.length > 0
                ? ` Also reported by ${currentReport.coReporters.join(', ')}.`
                : ''}
            </p>
            <Link href={`/dashboard/reports/duplicates?reportId=${currentReport.id}`} className={styles.duplicateNoticeLink}>
              View all duplicate reports
              <Icon name="document-forward" size={14} />
            </Link>
          </div>
        ) : null}
        <div className={styles.grid}>
          <section className={styles.mainColumn}>
            <motion.article className={styles.panel} whileHover={{ y: -2 }} transition={{ duration: 0.15 }} aria-label="Report summary">
              <div className={styles.image}>
                {activePhoto?.previewUrl ? (
                  <button
                    type="button"
                    className={styles.imagePreviewButton}
                    aria-label="Open photo in fullscreen"
                    onClick={() => setIsLightboxOpen(true)}
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
                  <span className={styles.reportNumber}>Report {currentReport.reportNumber}</span>
                  <span className={styles.location}>
                    <Icon name="location" size={14} />
                    {currentReport.location}
                  </span>
                </div>
              </div>
              {photoEvidence.length > 0 ? (
                <div className={styles.photoStrip} role="tablist" aria-label="Report photos">
                  {photoEvidence.map((item) => (
                    <button
                      key={item.id}
                      type="button"
                      role="tab"
                      aria-selected={item.id === activePhoto?.id}
                      className={`${styles.photoThumb} ${item.id === activePhoto?.id ? styles.photoThumbActive : ''}`}
                      onClick={() => {
                        setActivePhotoId(item.id);
                        setIsLightboxOpen(true);
                      }}
                    >
                      {item.previewUrl ? (
                        <Image
                          src={item.previewUrl}
                          alt={item.previewAlt ?? item.label}
                          loading="lazy"
                          width={86}
                          height={64}
                        />
                      ) : null}
                    </button>
                  ))}
                </div>
              ) : null}
              <div className={styles.body}>
                {currentReport.description.trim().length > 0 ? (
                  <p className={styles.reportText}>{currentReport.description}</p>
                ) : null}
                <div className={styles.metaGrid}>
                  <button
                    type="button"
                    className={styles.metaGridItem}
                    disabled={isTerminalStatus}
                    onClick={() => setContextDetailModal('submitted')}
                    aria-label="View submission details"
                  >
                    <span className={styles.metaIcon} aria-hidden>
                      <Icon name="calendar" size={14} />
                    </span>
                    <div>
                      <span className={styles.metaLabel}>Submitted</span>
                      <span className={styles.metaValue}>{formatDateTime(currentReport.submittedAt)}</span>
                    </div>
                  </button>
                  <button
                    type="button"
                    className={styles.metaGridItem}
                    disabled={isTerminalStatus}
                    onClick={() => setContextDetailModal('reporter')}
                    aria-label="View reporter details"
                  >
                    <span className={styles.metaIcon} aria-hidden>
                      <Icon name="user" size={14} />
                    </span>
                    <div>
                      <span className={styles.metaLabel}>Reporter</span>
                      <span className={styles.metaValue}>{currentReport.reporterAlias}</span>
                    </div>
                  </button>
                  {currentReport.cleanupEffortLabel ? (
                    <div className={styles.metaGridItem} aria-label="Cleanup effort from citizen">
                      <span className={styles.metaIcon} aria-hidden>
                        <Icon name="users" size={14} />
                      </span>
                      <div>
                        <span className={styles.metaLabel}>Cleanup effort</span>
                        <span className={styles.metaValue}>{currentReport.cleanupEffortLabel}</span>
                      </div>
                    </div>
                  ) : null}
                  {currentReport.coReporters.length > 0 && !currentReport.isPotentialDuplicate ? (
                    <button
                      type="button"
                      className={styles.metaGridItem}
                      disabled={isTerminalStatus}
                      onClick={() => setContextDetailModal('co-reporters')}
                      aria-label="View co-reporters details"
                    >
                      <span className={styles.metaIcon} aria-hidden>
                        <Icon name="users" size={14} />
                      </span>
                      <div>
                        <span className={styles.metaLabel}>Also reported by</span>
                        <span className={styles.metaValue}>{currentReport.coReporters.join(', ')}</span>
                      </div>
                    </button>
                  ) : null}
                  <button
                    type="button"
                    className={styles.metaGridItem}
                    disabled={isTerminalStatus}
                    onClick={() => setContextDetailModal('trust-tier')}
                    aria-label="View trust tier details"
                  >
                    <span className={styles.metaIcon} aria-hidden>
                      <Icon name="shield" size={14} />
                    </span>
                    <div>
                      <span className={styles.metaLabel}>Trust tier</span>
                      <span className={styles.metaValue}>{currentReport.reporterTrust}</span>
                    </div>
                  </button>
                  <button
                    type="button"
                    className={styles.metaGridItem}
                    disabled={isTerminalStatus}
                    onClick={() => setContextDetailModal('queue')}
                    aria-label="View queue details"
                  >
                    <span className={styles.metaIcon} aria-hidden>
                      <Icon name="scroll-text" size={14} />
                    </span>
                    <div>
                      <span className={styles.metaLabel}>Queue</span>
                      <span className={styles.metaValue}>{currentReport.moderation.queueLabel}</span>
                    </div>
                  </button>
                </div>
              </div>
            </motion.article>

            <ReportReviewEvidencePanel
              evidence={currentReport.evidence}
              onOpenImageEvidence={(evidenceId) => {
                setActivePhotoId(evidenceId);
                setIsLightboxOpen(true);
              }}
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

            <motion.article
              ref={contextPanelRef}
              className={`${styles.panel} ${styles.railPanel} ${styles.contextPanel}`}
              whileHover={{ y: -2 }}
              transition={{ duration: 0.15 }}
            >
              <div className={styles.contextHeader}>
                <h3 className={styles.railTitle}>Operational context</h3>
                <button
                  type="button"
                  className={styles.contextInfoBtn}
                  onClick={() => setIsContextLegendOpen((v) => !v)}
                  aria-expanded={isContextLegendOpen}
                  aria-label="Show operational context legend"
                  title="What do these fields mean?"
                >
                  <Icon name="info" size={16} />
                </button>
              </div>
              {isContextLegendOpen && (
                <div className={styles.contextLegend} role="region" aria-label="Operational context legend">
                  <div className={styles.contextLegendItem}>
                    <span className={styles.contextLegendTerm}>Assigned team</span>
                    <p className={styles.contextLegendDesc}>
                      The moderation team currently responsible for reviewing and triaging this report. Tasks are distributed across teams (e.g. City Moderation, Regional) for workload balance and domain expertise.
                    </p>
                  </div>
                  <div className={styles.contextLegendItem}>
                    <span className={styles.contextLegendTerm}>SLA</span>
                    <p className={styles.contextLegendDesc}>
                      Service Level Agreement — the time remaining before a response or decision is expected. Critical reports may show 1h or less; typical targets are 2–4h. When the SLA expires, the report escalates for prioritization.
                    </p>
                  </div>
                  <div className={styles.contextLegendItem}>
                    <span className={styles.contextLegendTerm}>Current queue</span>
                    <p className={styles.contextLegendDesc}>
                      The work stream or category this report belongs to (e.g. General Queue, Priority Queue). Queues help organize reports by urgency, type, or workflow stage so moderators can focus on the right batch.
                    </p>
                  </div>
                </div>
              )}
              <dl className={styles.contextList}>
                <div className={styles.contextItem}>
                  <span className={styles.contextIcon} aria-hidden>
                    <Icon name="users" size={16} />
                  </span>
                  <div className={styles.contextContent}>
                    <dt>Assigned team</dt>
                    <dd>{currentReport.moderation.assignedTeam}</dd>
                  </div>
                </div>
                <div className={`${styles.contextItem} ${styles[`sla${slaUrgency.charAt(0).toUpperCase() + slaUrgency.slice(1)}`]}`}>
                  <span className={styles.contextIcon} aria-hidden>
                    <Icon name="calendar" size={16} />
                  </span>
                  <div className={styles.contextContent}>
                    <dt>SLA</dt>
                    <dd>{currentReport.moderation.slaLabel}</dd>
                  </div>
                </div>
                <div className={styles.contextItem}>
                  <span className={styles.contextIcon} aria-hidden>
                    <Icon name="scroll-text" size={16} />
                  </span>
                  <div className={styles.contextContent}>
                    <dt>Current queue</dt>
                    <dd>{currentReport.moderation.queueLabel}</dd>
                  </div>
                </div>
              </dl>
            </motion.article>

            <motion.article className={`${styles.panel} ${styles.railPanel}`} whileHover={{ y: -2 }} transition={{ duration: 0.15 }}>
              <LocationMapCard
                mapPin={currentReport.mapPin}
                locationLabel={currentReport.mapPin.label || currentReport.location}
              />
            </motion.article>
          </aside>
        </div>
        <Snack snack={snack} onClose={clearSnack} />
      </Card>
      {typeof document !== 'undefined' && document.body
        ? createPortal(
            <AnimatePresence mode="wait">
              {isLightboxOpen && activePhoto?.previewUrl ? (
                <motion.div
                  className={styles.lightboxBackdrop}
                  role="dialog"
                  aria-modal="true"
                  aria-label="Evidence photo preview"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 0.24 }}
                  onMouseDown={(event) => {
                    if (event.target !== event.currentTarget) return;
                    setIsLightboxOpen(false);
                  }}
                >
                  <motion.div
                    className={styles.lightbox}
                    initial={{ opacity: 0, scale: 0.94, y: 12 }}
                    animate={{ opacity: 1, scale: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.94, y: 12 }}
                    transition={{ duration: 0.28, ease: [0.25, 0.46, 0.45, 0.94] }}
                  >
                    <div className={styles.lightboxHeader}>
                      <p className={styles.lightboxLabel}>{activePhoto.label}</p>
                      <button
                        type="button"
                        className={styles.lightboxClose}
                        aria-label="Close photo preview"
                        onClick={() => setIsLightboxOpen(false)}
                      >
                        <Icon name="x" size={18} />
                      </button>
                    </div>
                    <div className={styles.lightboxBody}>
                      {photoEvidence.length > 1 ? (
                        <button
                          type="button"
                          className={styles.lightboxNav}
                          aria-label="Previous photo"
                          onClick={showPreviousPhoto}
                        >
                          <Icon name="chevron-left" size={22} />
                        </button>
                      ) : null}
                      <div className={styles.lightboxImageWrap}>
                        <motion.div
                          key={activePhoto.id}
                          className={styles.lightboxImageInner}
                          initial={{ opacity: 0 }}
                          animate={{ opacity: 1 }}
                          transition={{ duration: 0.2 }}
                        >
                          <Image
                            src={activePhoto.previewUrl}
                            alt={activePhoto.previewAlt ?? activePhoto.label}
                            className={styles.lightboxImage}
                            loading="lazy"
                            width={1600}
                            height={1000}
                          />
                        </motion.div>
                      </div>
                      {photoEvidence.length > 1 ? (
                        <button type="button" className={styles.lightboxNav} aria-label="Next photo" onClick={showNextPhoto}>
                          <Icon name="chevron-right" size={22} />
                        </button>
                      ) : null}
                    </div>
                    <div className={styles.lightboxFooter}>
                      {photoEvidence.length > 1 ? (
                        <>
                          <div className={styles.lightboxPager}>
                            {photoEvidence.map((_, i) => (
                              <span
                                key={i}
                                className={`${styles.lightboxDot} ${i === activePhotoIndex ? styles.lightboxDotActive : ''}`}
                                aria-hidden
                              />
                            ))}
                          </div>
                          <div className={styles.lightboxFilmstripWrap}>
                            <div ref={filmstripRef} className={styles.lightboxFilmstrip} role="tablist" aria-label="Photo thumbnails">
                              {photoEvidence.map((item, i) => (
                                <button
                                  key={item.id}
                                  ref={(el) => {
                                    thumbRefs.current.set(i, el);
                                  }}
                                  type="button"
                                  role="tab"
                                  aria-selected={item.id === activePhoto?.id}
                                  className={`${styles.lightboxThumb} ${item.id === activePhoto?.id ? styles.lightboxThumbActive : ''}`}
                                  onClick={() => setActivePhotoId(item.id)}
                                >
                                  {item.previewUrl ? (
                                    <Image src={item.previewUrl} alt="" width={80} height={60} />
                                  ) : null}
                                </button>
                              ))}
                            </div>
                          </div>
                        </>
                      ) : null}
                      <p className={styles.lightboxMeta}>
                        {activePhotoIndex + 1} of {photoEvidence.length}
                        {activePhoto.sizeLabel ? ` · ${activePhoto.sizeLabel}` : ''}
                      </p>
                    </div>
                  </motion.div>
                </motion.div>
              ) : null}
            </AnimatePresence>,
            document.body,
          )
        : null}
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
        onSelectedReasonChange={(value) => {
          setRejectionReason(value);
          if (rejectionReasonError) {
            setRejectionReasonError(null);
          }
        }}
        onNotesChange={(value) => setRejectionNotes(value)}
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
