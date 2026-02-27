'use client';

import Image from 'next/image';
import { KeyboardEvent as ReactKeyboardEvent, useEffect, useMemo, useRef, useState } from 'react';
import { motion } from 'framer-motion';
import { Button, Card, Icon, SectionState, Snack } from '@/components/ui';
import { rejectionReasonOptions } from '../constants/rejection-reasons';
import { useReportReview } from '../hooks/use-report-review';
import { ActionConfirmModal } from './action-confirm-modal';
import { ReportDetail, ReportEvidence, ReportTimelineEntry } from '../types';
import { formatReportStatus, statusIconName } from '../utils/report-status';
import styles from './report-review-card.module.css';

type ReportReviewCardProps = {
  report: ReportDetail;
};

function statusClassName(status: ReportDetail['status']) {
  const statusClassByName: Record<ReportDetail['status'], string> = {
    NEW: styles.statusNew,
    IN_REVIEW: styles.statusInReview,
    APPROVED: styles.statusApproved,
    DELETED: styles.statusDeleted,
  };

  return `${styles.statusPill} ${statusClassByName[status]}`;
}

function priorityClassName(priority: ReportDetail['priority']) {
  const priorityClassByName: Record<ReportDetail['priority'], string> = {
    LOW: styles.priorityLow,
    MEDIUM: styles.priorityMedium,
    HIGH: styles.priorityHigh,
    CRITICAL: styles.priorityCritical,
  };

  return `${styles.priorityPill} ${priorityClassByName[priority]}`;
}

function timelineToneClassName(tone: ReportTimelineEntry['tone']) {
  const classByTone: Record<ReportTimelineEntry['tone'], string> = {
    neutral: styles.timelineToneNeutral,
    info: styles.timelineToneInfo,
    success: styles.timelineToneSuccess,
    warning: styles.timelineToneWarning,
  };

  return classByTone[tone];
}

function evidenceIconName(kind: ReportEvidence['kind']) {
  if (kind === 'video') {
    return 'document-forward';
  }

  if (kind === 'document') {
    return 'clipboard-close';
  }

  return 'document-text';
}

function formatDateTime(value: string) {
  return new Intl.DateTimeFormat('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value));
}

function buildMapEmbedUrl(latitude: number, longitude: number) {
  const delta = 0.008;
  const left = longitude - delta;
  const right = longitude + delta;
  const top = latitude + delta;
  const bottom = latitude - delta;
  return `https://www.openstreetmap.org/export/embed.html?bbox=${left}%2C${bottom}%2C${right}%2C${top}&layer=mapnik&marker=${latitude}%2C${longitude}`;
}

function buildMapExternalUrl(latitude: number, longitude: number) {
  return `https://www.openstreetmap.org/?mlat=${latitude}&mlon=${longitude}#map=15/${latitude}/${longitude}`;
}

export function ReportReviewCard({ report }: ReportReviewCardProps) {
  const { report: currentReport, isUpdating, snack, setInReview, approveReport, rejectReport, clearSnack } = useReportReview(report);
  const actionButtonsRef = useRef<Array<HTMLButtonElement | null>>([]);
  const [pendingAction, setPendingAction] = useState<'set-in-review' | 'approve' | 'reject' | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [rejectionNotes, setRejectionNotes] = useState('');
  const [rejectionReasonError, setRejectionReasonError] = useState<string | null>(null);
  const [activePhotoId, setActivePhotoId] = useState<string | null>(null);
  const [isLightboxOpen, setIsLightboxOpen] = useState(false);

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

  function onActionRailKeyDown(event: ReactKeyboardEvent<HTMLDivElement>) {
    const key = event.key;
    if (key !== 'ArrowDown' && key !== 'ArrowUp' && key !== 'Home' && key !== 'End') {
      return;
    }

    const activeIndex = actionButtonsRef.current.findIndex((button) => button === document.activeElement);

    if (activeIndex === -1 && key !== 'Home' && key !== 'End') {
      return;
    }

    event.preventDefault();

    if (key === 'Home') {
      actionButtonsRef.current[0]?.focus();
      return;
    }

    if (key === 'End') {
      actionButtonsRef.current[actionButtonsRef.current.length - 1]?.focus();
      return;
    }

    const step = key === 'ArrowDown' ? 1 : -1;
    const nextIndex = (activeIndex + step + actionButtonsRef.current.length) % actionButtonsRef.current.length;
    actionButtonsRef.current[nextIndex]?.focus();
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
      await rejectReport(composedReason);
      closeConfirmModal();
      return;
    }

    if (pendingAction === 'approve') {
      await approveReport();
      closeConfirmModal();
      return;
    }

    await setInReview();
    closeConfirmModal();
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
      <Card className={styles.card}>
        <header className={styles.header}>
          <div>
            <p className={styles.kicker}>Moderation workspace</p>
            <h2 className={styles.title}>{currentReport.title}</h2>
          </div>
          <div className={styles.headerPills}>
            <span className={statusClassName(currentReport.status)}>
              <Icon name={statusIconName(currentReport.status)} size={12} />
              {formatReportStatus(currentReport.status)}
            </span>
            <span className={priorityClassName(currentReport.priority)}>{currentReport.priority} priority</span>
            {currentReport.isPotentialDuplicate ? (
              <span className={styles.duplicatePill}>
                <Icon name="alert-triangle" size={12} />
                {currentReport.potentialDuplicateOfReportNumber
                  ? `Maybe duplicate of ${currentReport.potentialDuplicateOfReportNumber}`
                  : 'Maybe duplicate report'}
              </span>
            ) : null}
          </div>
        </header>
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
                      onClick={() => setActivePhotoId(item.id)}
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
                <p className={styles.reportText}>{currentReport.description}</p>
                <dl className={styles.metaGrid}>
                  <div>
                    <dt>Submitted</dt>
                    <dd>{formatDateTime(currentReport.submittedAt)}</dd>
                  </div>
                  <div>
                    <dt>Reporter</dt>
                    <dd>{currentReport.reporterAlias}</dd>
                  </div>
                  {currentReport.coReporters.length > 0 ? (
                    <div>
                      <dt>Also reported by</dt>
                      <dd>{currentReport.coReporters.join(', ')}</dd>
                    </div>
                  ) : null}
                  <div>
                    <dt>Trust tier</dt>
                    <dd>{currentReport.reporterTrust}</dd>
                  </div>
                  <div>
                    <dt>Queue</dt>
                    <dd>{currentReport.moderation.queueLabel}</dd>
                  </div>
                </dl>
              </div>
            </motion.article>

            <motion.article className={styles.panel} whileHover={{ y: -2 }} transition={{ duration: 0.15 }} aria-label="Evidence files">
              <div className={styles.sectionHeader}>
                <h3>Evidence</h3>
                <span>{currentReport.evidence.length} files</span>
              </div>
              {currentReport.evidence.length === 0 ? (
                <div className={styles.sectionEmpty}>
                  <SectionState variant="empty" message="No evidence files were attached to this report." />
                </div>
              ) : (
                <ul className={styles.evidenceList}>
                  {currentReport.evidence.map((item) => (
                    <li key={item.id} className={styles.evidenceItem} tabIndex={0}>
                      <span className={styles.evidenceIcon}>
                        <Icon name={evidenceIconName(item.kind)} size={14} />
                      </span>
                      <span className={styles.evidenceLabel}>{item.label}</span>
                      <span className={styles.evidenceMeta}>
                        {item.sizeLabel} • {formatDateTime(item.uploadedAt)}
                      </span>
                    </li>
                  ))}
                </ul>
              )}
            </motion.article>

            <motion.article className={styles.panel} whileHover={{ y: -2 }} transition={{ duration: 0.15 }} aria-label="Report timeline">
              <div className={styles.sectionHeader}>
                <h3>Lifecycle timeline</h3>
                <span>{currentReport.timeline.length} events</span>
              </div>
              {currentReport.timeline.length === 0 ? (
                <div className={styles.sectionEmpty}>
                  <SectionState variant="empty" message="Timeline entries will appear as moderation actions are performed." />
                </div>
              ) : (
                <ol className={styles.timeline}>
                  {currentReport.timeline.map((entry) => (
                    <li key={entry.id} className={styles.timelineItem} tabIndex={0}>
                      <span className={`${styles.timelineDot} ${timelineToneClassName(entry.tone)}`} aria-hidden />
                      <div className={styles.timelineBody}>
                        <div className={styles.timelineHeading}>
                          <strong>{entry.title}</strong>
                          <time>{formatDateTime(entry.occurredAt)}</time>
                        </div>
                        <p>{entry.detail}</p>
                        <span>By {entry.actor}</span>
                      </div>
                    </li>
                  ))}
                </ol>
              )}
            </motion.article>
          </section>

          <aside className={styles.actionRail}>
            <motion.article className={`${styles.panel} ${styles.railPanel}`} whileHover={{ y: -2 }} transition={{ duration: 0.15 }}>
              <h3 className={styles.railTitle}>Moderation actions</h3>
              <p className={styles.railText}>
                Apply an explicit decision and keep the lifecycle clean. Every action writes a timeline entry.
              </p>
              <p className={styles.shortcutHint}>Tip: use Arrow keys to move between actions.</p>
              <div className={styles.actions} role="toolbar" aria-label="Moderation actions" onKeyDown={onActionRailKeyDown}>
                <Button
                  variant="outline"
                  onClick={() => setPendingAction('set-in-review')}
                  isLoading={isUpdating}
                  ref={(element) => {
                    actionButtonsRef.current[0] = element;
                  }}
                >
                  <Icon name="document-text" size={14} />
                  Set in review
                </Button>
                <Button
                  onClick={() => setPendingAction('approve')}
                  isLoading={isUpdating}
                  ref={(element) => {
                    actionButtonsRef.current[1] = element;
                  }}
                >
                  <Icon name="check" size={14} />
                  Approve report
                </Button>
                <Button
                  variant="outline"
                  onClick={() => setPendingAction('reject')}
                  isLoading={isUpdating}
                  ref={(element) => {
                    actionButtonsRef.current[2] = element;
                  }}
                >
                  <Icon name="trash" size={14} />
                  Reject report
                </Button>
              </div>
            </motion.article>

            <motion.article className={`${styles.panel} ${styles.railPanel}`} whileHover={{ y: -2 }} transition={{ duration: 0.15 }}>
              <h3 className={styles.railTitle}>Operational context</h3>
              <dl className={styles.contextList}>
                <div>
                  <dt>Assigned team</dt>
                  <dd>{currentReport.moderation.assignedTeam}</dd>
                </div>
                <div>
                  <dt>SLA</dt>
                  <dd>{currentReport.moderation.slaLabel}</dd>
                </div>
                <div>
                  <dt>Current queue</dt>
                  <dd>{currentReport.moderation.queueLabel}</dd>
                </div>
              </dl>
            </motion.article>

            <motion.article className={`${styles.panel} ${styles.railPanel}`} whileHover={{ y: -2 }} transition={{ duration: 0.15 }}>
              <h3 className={styles.railTitle}>Location map</h3>
              <p className={styles.railText}>{currentReport.mapPin.label}</p>
              <div className={styles.mapFrameWrap}>
                <iframe
                  className={styles.mapFrame}
                  title={`Map location for ${currentReport.location}`}
                  src={buildMapEmbedUrl(currentReport.mapPin.latitude, currentReport.mapPin.longitude)}
                  loading="lazy"
                  referrerPolicy="no-referrer-when-downgrade"
                />
              </div>
              <a
                className={styles.mapLink}
                href={buildMapExternalUrl(currentReport.mapPin.latitude, currentReport.mapPin.longitude)}
                target="_blank"
                rel="noreferrer"
              >
                Open in OpenStreetMap
                <Icon name="document-forward" size={14} />
              </a>
            </motion.article>
          </aside>
        </div>
        <Snack snack={snack} onClose={clearSnack} />
      </Card>
      {isLightboxOpen && activePhoto?.previewUrl ? (
        <div
          className={styles.lightboxBackdrop}
          role="dialog"
          aria-modal="true"
          aria-label="Evidence photo preview"
          onMouseDown={(event) => {
            if (event.target !== event.currentTarget) {
              return;
            }

            setIsLightboxOpen(false);
          }}
        >
          <div className={styles.lightbox}>
            <div className={styles.lightboxHeader}>
              <p className={styles.lightboxLabel}>{activePhoto.label}</p>
              <button
                type="button"
                className={styles.lightboxClose}
                aria-label="Close photo preview"
                onClick={() => setIsLightboxOpen(false)}
              >
                <Icon name="x" size={16} />
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
                  <Icon name="chevron-left" size={18} />
                </button>
              ) : null}
              <Image
                src={activePhoto.previewUrl}
                alt={activePhoto.previewAlt ?? activePhoto.label}
                className={styles.lightboxImage}
                loading="lazy"
                width={1200}
                height={800}
              />
              {photoEvidence.length > 1 ? (
                <button type="button" className={styles.lightboxNav} aria-label="Next photo" onClick={showNextPhoto}>
                  <Icon name="chevron-right" size={18} />
                </button>
              ) : null}
            </div>
            <p className={styles.lightboxMeta}>
              {activePhotoIndex + 1} of {photoEvidence.length} • {activePhoto.sizeLabel}
            </p>
          </div>
        </div>
      ) : null}
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
    </motion.div>
  );
}
