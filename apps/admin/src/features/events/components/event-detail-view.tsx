'use client';

import Link from 'next/link';
import { KeyboardEvent as ReactKeyboardEvent, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Icon } from '@/components/ui';
import { useUnsavedChangesGuard } from '@/features/admin-shell/hooks/use-unsaved-changes-guard';
import type { CleanupEventDetail } from '@/features/events/data/events-adapter';
import { useEventDetailForm } from '@/features/events/hooks/use-event-detail-form';
import { useEventDetailMutations } from '@/features/events/hooks/use-event-detail-mutations';
import { toDatetimeLocalField } from '@/features/events/lib/event-admin-datetime';
import { EventDetailAfterPhotos, EventDetailContextSection } from './event-detail-after-photos';
import { CleanupEventFormFields } from './cleanup-event-form-fields';
import { DeclineReasonModal } from './decline-reason-modal';
import { DuplicateEventModal } from './duplicate-event-modal';
import { EventDetailHeader } from './event-detail-header';
import { EventDetailLifecyclePanel } from './event-detail-lifecycle-panel';
import { EventDetailMetaPanel } from './event-detail-meta-panel';
import { EventDetailModerationActionRail } from './event-detail-moderation-action-rail';
import { EventDetailSiteSection } from './event-detail-site-section';
import { EventDetailTabs } from './event-detail-tabs';
import styles from './event-detail.module.css';

type EventDetailViewProps = {
  event: CleanupEventDetail;
  canWriteCleanupEvents: boolean;
  declineReason?: string | null;
  declineReasonLoadError?: string | null;
};

export function EventDetailView({
  event,
  canWriteCleanupEvents,
  declineReason = null,
  declineReasonLoadError = null,
}: EventDetailViewProps) {
  const form = useEventDetailForm(event);
  const mutations = useEventDetailMutations(event, form);
  useUnsavedChangesGuard(form.isDirty);
  const tDetail = useTranslations('events.detail');
  const tCommon = useTranslations('common');

  const readOnly = !canWriteCleanupEvents;
  const actionButtonsRef = useRef<Array<HTMLButtonElement | null>>([]);
  const [returnToPendingOpen, setReturnToPendingOpen] = useState(false);

  const isApproveDisabled = readOnly || !form.isPending || mutations.saving || form.isDirty;
  const isDeclineDisabled = readOnly || !form.isPending || mutations.saving || form.isDirty;
  const isReturnDisabled =
    readOnly ||
    (event.status !== 'APPROVED' && event.status !== 'DECLINED') ||
    mutations.saving ||
    form.isDirty;
  const actionDisabledFlags = [isApproveDisabled, isDeclineDisabled, isReturnDisabled];

  function onActionRailKeyDown(event: ReactKeyboardEvent<HTMLDivElement>) {
    const key = event.key;
    if (key !== 'ArrowDown' && key !== 'ArrowUp' && key !== 'Home' && key !== 'End') {
      return;
    }
    const activeIndex = actionButtonsRef.current.findIndex((button) => button === document.activeElement);
    const enabledIndices = actionDisabledFlags.map((disabled, i) => (disabled ? -1 : i)).filter((i) => i >= 0);
    if (enabledIndices.length === 0) return;
    if (activeIndex === -1 && key !== 'Home' && key !== 'End') return;
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
    <div className={styles.pageRoot}>
      <Link href="/dashboard/events" className={styles.backLink}>
        <Icon name="chevron-left" size={16} />
        {tDetail('backToEvents')}
      </Link>

      <div className={styles.detailGrid}>
        <div className={styles.mainColumn}>
          <EventDetailHeader
            event={event}
            declineReason={declineReason}
            declineReasonLoadError={declineReasonLoadError}
          />

          <EventDetailContextSection event={event} />

          {event.afterImageUrls && event.afterImageUrls.length > 0 ? (
            <EventDetailAfterPhotos afterImageUrls={event.afterImageUrls} />
          ) : null}

          <EventDetailMetaPanel event={event} />
          <EventDetailSiteSection site={event.site} />

          <EventDetailLifecyclePanel
            event={event}
            canWrite={canWriteCleanupEvents}
            saving={mutations.saving}
            isDirty={form.isDirty}
            onStartInProgress={() => void mutations.patchLifecycle('IN_PROGRESS')}
            onMarkComplete={() => void mutations.markComplete()}
            onCancel={() => void mutations.patchLifecycle('CANCELLED')}
          />

          {form.isDirty ? (
            <div className={styles.readOnlyBanner} role="status">
              {tDetail('unsavedChanges')}
            </div>
          ) : null}

          {readOnly ? (
            <div className={styles.readOnlyBanner} role="status">
              {tDetail('readOnlyBanner')}
            </div>
          ) : null}

          <section className={styles.sectionCard}>
            <span className={styles.sectionLabel}>{tDetail('editEvent')}</span>
            <p className={styles.moderationHint}>
              {form.isPending ? tDetail('moderationHintPending') : tDetail('moderationHintEdit')}
            </p>
            <div className={styles.form}>
              <CleanupEventFormFields
                idPrefix="detail-event"
                values={form.formValues}
                fieldErrors={mutations.fieldErrors}
                readOnly={readOnly}
                showEndAt={!form.isCompleted}
                recurrenceHint={tDetail('recurrenceClearHint')}
                recurrencePlaceholder={tDetail('recurrenceClearPlaceholder')}
                useInputComponentForParticipants
                scheduleConflictHint={form.scheduleConflictHint}
                scheduleConflictChecking={form.scheduleConflictChecking}
                scheduleConflictFetchFailed={form.scheduleConflictFetchFailed}
                scheduleConflictOverride={form.scheduleConflictOverride}
                onScheduleConflictOverrideChange={form.setScheduleConflictOverride}
                onFieldChange={form.handleFormFieldChange}
                onClearFieldError={mutations.clearFieldError}
              />

              {form.isCompleted ? (
                <label className={styles.field} htmlFor="detail-event-completed">
                  <span className={styles.fieldLabel}>{tDetail('completedDateTime')}</span>
                  <input
                    id="detail-event-completed"
                    type="datetime-local"
                    value={form.completedAt ? toDatetimeLocalField(form.completedAt) : ''}
                    disabled={readOnly}
                    onChange={(e) => {
                      form.setCompletedAt(e.target.value ? new Date(e.target.value).toISOString() : '');
                      mutations.clearFieldError('completedAt');
                    }}
                    className={styles.input}
                    aria-invalid={mutations.fieldErrors.completedAt ? true : undefined}
                    aria-describedby={
                      mutations.fieldErrors.completedAt ? 'detail-event-completed-err' : undefined
                    }
                  />
                  <span className={styles.fieldHint}>{tDetail('completedDateHint')}</span>
                  {mutations.fieldErrors.completedAt ? (
                    <span id="detail-event-completed-err" className={styles.fieldError} role="alert">
                      {mutations.fieldErrors.completedAt}
                    </span>
                  ) : null}
                </label>
              ) : null}

              <div className={styles.formActions}>
                <Button
                  onClick={() => void mutations.saveUpdates()}
                  isLoading={mutations.saving}
                  disabled={readOnly || !form.isDirty}
                >
                  {tCommon('saveChanges')}
                </Button>
              </div>
            </div>
          </section>

          <EventDetailTabs eventId={event.id} canWrite={canWriteCleanupEvents} />
        </div>

        <EventDetailModerationActionRail
          event={event}
          canWriteCleanupEvents={canWriteCleanupEvents}
          saving={mutations.saving}
          isDirty={form.isDirty}
          actionButtonsRef={actionButtonsRef}
          onActionRailKeyDown={onActionRailKeyDown}
          onApprove={() => void mutations.approve()}
          onDecline={mutations.openDeclineModal}
          onReturnToPending={() => setReturnToPendingOpen(true)}
          returnToPendingOpen={returnToPendingOpen}
          onReturnToPendingConfirm={() => {
            void mutations.returnToPending().finally(() => setReturnToPendingOpen(false));
          }}
          onReturnToPendingClose={() => setReturnToPendingOpen(false)}
        />
      </div>

      {mutations.duplicateModal ? (
        <DuplicateEventModal
          open
          conflict={mutations.duplicateModal}
          onClose={() => mutations.setDuplicateModal(null)}
        />
      ) : null}

      <DeclineReasonModal
        open={mutations.declineModalOpen}
        reason={mutations.declineReason}
        reasonError={mutations.declineReasonError}
        saving={mutations.saving}
        onReasonChange={(value) => {
          mutations.setDeclineReason(value);
          mutations.setDeclineReasonError(null);
        }}
        onClose={mutations.closeDeclineModal}
        onSubmit={() => void mutations.submitDecline()}
      />
    </div>
  );
}
