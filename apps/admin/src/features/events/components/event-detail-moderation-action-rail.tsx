'use client';

import type { KeyboardEvent as ReactKeyboardEvent, MutableRefObject } from 'react';
import { useTranslations } from 'next-intl';
import { Button, ConfirmDialog, Icon } from '@/components/ui';
import type { CleanupEventDetail } from '@/features/events/data/events-adapter';
import styles from './event-detail.module.css';

type EventDetailModerationActionRailProps = {
  event: CleanupEventDetail;
  canWriteCleanupEvents: boolean;
  saving: boolean;
  isDirty: boolean;
  actionButtonsRef: MutableRefObject<Array<HTMLButtonElement | null>>;
  onActionRailKeyDown: (event: ReactKeyboardEvent<HTMLDivElement>) => void;
  onApprove: () => void;
  onDecline: () => void;
  onReturnToPending: () => void;
  returnToPendingOpen: boolean;
  onReturnToPendingConfirm: () => void;
  onReturnToPendingClose: () => void;
};

export function EventDetailModerationActionRail({
  event,
  canWriteCleanupEvents,
  saving,
  isDirty,
  actionButtonsRef,
  onActionRailKeyDown,
  onApprove,
  onDecline,
  onReturnToPending,
  returnToPendingOpen,
  onReturnToPendingConfirm,
  onReturnToPendingClose,
}: EventDetailModerationActionRailProps) {
  const tDetail = useTranslations('events.detail');
  const moderationStatus = event.status ?? 'APPROVED';
  const isPending = moderationStatus === 'PENDING';
  const isResolved = moderationStatus === 'APPROVED' || moderationStatus === 'DECLINED';
  const readOnly = !canWriteCleanupEvents;

  const isApproveDisabled = readOnly || !isPending || saving || isDirty;
  const isDeclineDisabled = readOnly || !isPending || saving || isDirty;
  const isReturnDisabled = readOnly || !isResolved || saving || isDirty;
  const allActionsDisabled = isApproveDisabled && isDeclineDisabled && isReturnDisabled;

  return (
    <aside className={styles.railPanel} aria-label={tDetail('moderationRailAria')}>
      <h3 className={styles.railTitle}>{tDetail('moderation')}</h3>
      {readOnly ? (
        <p className={styles.approveDeclineHint} role="note">
          {isPending ? tDetail('moderationPendingReadOnly') : tDetail('readOnlyBanner')}
        </p>
      ) : null}
      {isPending && canWriteCleanupEvents ? (
        <p className={styles.approveDeclineHint}>{tDetail('moderationPendingHint')}</p>
      ) : null}
      {isResolved && canWriteCleanupEvents ? (
        <p className={styles.approveDeclineHint}>{tDetail('moderationResolvedHint')}</p>
      ) : null}
      {isDirty ? (
        <p className={styles.fieldError} role="status">
          {tDetail('unsavedChangesActionBlocked')}
        </p>
      ) : null}
      {!allActionsDisabled || isResolved ? (
        <div
          className={styles.railActions}
          role="toolbar"
          aria-label={tDetail('moderationToolbarAria')}
          onKeyDown={onActionRailKeyDown}
        >
          {isPending && canWriteCleanupEvents ? (
            <>
              <Button
                onClick={onApprove}
                isLoading={saving}
                disabled={isApproveDisabled}
                aria-label={tDetail('approve')}
                ref={(el) => {
                  actionButtonsRef.current[0] = el;
                }}
              >
                <Icon name="check" size={14} />
                {tDetail('approve')}
              </Button>
              <Button
                variant="outline"
                onClick={onDecline}
                disabled={isDeclineDisabled}
                className={styles.declineBtn}
                aria-label={tDetail('decline')}
                ref={(el) => {
                  actionButtonsRef.current[1] = el;
                }}
              >
                {tDetail('decline')}
              </Button>
            </>
          ) : null}
          {isResolved && canWriteCleanupEvents ? (
            <Button
              variant="outline"
              onClick={onReturnToPending}
              disabled={isReturnDisabled}
              aria-label={tDetail('returnToPending')}
              ref={(el) => {
                actionButtonsRef.current[2] = el;
              }}
            >
              {tDetail('returnToPending')}
            </Button>
          ) : null}
        </div>
      ) : null}
      {isResolved && !canWriteCleanupEvents ? (
        <p className={styles.fieldHint}>{tDetail('moderationResolvedReadOnly')}</p>
      ) : null}

      <ConfirmDialog
        open={returnToPendingOpen}
        title={tDetail('returnToPendingConfirmTitle')}
        description={tDetail('returnToPendingConfirmDescription')}
        confirmLabel={tDetail('returnToPendingConfirm')}
        cancelLabel={tDetail('keepCurrentStatus')}
        tone="danger"
        isLoading={saving}
        onConfirm={onReturnToPendingConfirm}
        onClose={onReturnToPendingClose}
      />
    </aside>
  );
}
