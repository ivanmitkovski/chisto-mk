'use client';

import { useTranslations } from 'next-intl';
import { Input } from '@/components/ui';
import type { CleanupEventFieldErrors } from '@/features/events/lib/admin-cleanup-event-validation';
import type { ConflictingEventInfo } from '@/features/events/lib/event-schedule-conflict-client';
import { ScheduleConflictBanner } from './schedule-conflict-banner';
import styles from './cleanup-event-form-fields.module.css';

export type CleanupEventFormValues = {
  title: string;
  description: string;
  recurrenceRule: string;
  scheduledAtLocal: string;
  endAtLocal: string;
  participantCount: number;
};

type CleanupEventFormFieldsProps = {
  idPrefix: string;
  values: CleanupEventFormValues;
  fieldErrors: CleanupEventFieldErrors;
  readOnly?: boolean;
  showEndAt?: boolean;
  recurrenceHint?: string;
  recurrencePlaceholder?: string;
  recurrenceLabel?: string;
  participantLabel?: string;
  useInputComponentForParticipants?: boolean;
  scheduleConflictHint?: ConflictingEventInfo | null;
  scheduleConflictChecking?: boolean;
  scheduleConflictFetchFailed?: boolean;
  scheduleConflictOverride?: boolean;
  onScheduleConflictOverrideChange?: (checked: boolean) => void;
  onFieldChange: <K extends keyof CleanupEventFormValues>(
    key: K,
    value: CleanupEventFormValues[K],
  ) => void;
  onClearFieldError: (key: keyof CleanupEventFieldErrors) => void;
  beforeParticipants?: React.ReactNode;
  afterParticipants?: React.ReactNode;
};

export function CleanupEventFormFields({
  idPrefix,
  values,
  fieldErrors,
  readOnly = false,
  showEndAt = true,
  recurrenceHint,
  recurrencePlaceholder,
  recurrenceLabel,
  participantLabel,
  useInputComponentForParticipants = false,
  scheduleConflictHint,
  scheduleConflictChecking = false,
  scheduleConflictFetchFailed = false,
  scheduleConflictOverride = false,
  onScheduleConflictOverrideChange,
  onFieldChange,
  onClearFieldError,
  beforeParticipants,
  afterParticipants,
}: CleanupEventFormFieldsProps) {
  const t = useTranslations('events');

  const resolvedRecurrenceLabel = recurrenceLabel ?? t('form.recurrenceLabelShort');
  const resolvedParticipantLabel = participantLabel ?? t('form.participantCountShort');

  return (
    <>
      <label className={styles.field} htmlFor={`${idPrefix}-title`}>
        <span className={styles.fieldLabel}>{t('form.title')}</span>
        <input
          id={`${idPrefix}-title`}
          type="text"
          value={values.title}
          disabled={readOnly}
          onChange={(e) => {
            onFieldChange('title', e.target.value);
            onClearFieldError('title');
          }}
          className={styles.inputWide}
          maxLength={200}
          aria-invalid={fieldErrors.title ? true : undefined}
          aria-describedby={fieldErrors.title ? `${idPrefix}-title-err` : undefined}
        />
        {fieldErrors.title ? (
          <span id={`${idPrefix}-title-err`} className={styles.fieldError} role="alert">
            {fieldErrors.title}
          </span>
        ) : null}
      </label>

      <label className={styles.field} htmlFor={`${idPrefix}-description`}>
        <span className={styles.fieldLabel}>{t('form.description')}</span>
        <textarea
          id={`${idPrefix}-description`}
          value={values.description}
          disabled={readOnly}
          onChange={(e) => {
            onFieldChange('description', e.target.value);
            onClearFieldError('description');
          }}
          className={styles.textarea}
          rows={4}
          maxLength={10000}
          aria-invalid={fieldErrors.description ? true : undefined}
          aria-describedby={fieldErrors.description ? `${idPrefix}-description-err` : undefined}
        />
        {fieldErrors.description ? (
          <span id={`${idPrefix}-description-err`} className={styles.fieldError} role="alert">
            {fieldErrors.description}
          </span>
        ) : null}
      </label>

      <label className={styles.field} htmlFor={`${idPrefix}-rrule`}>
        <span className={styles.fieldLabel}>{resolvedRecurrenceLabel}</span>
        <textarea
          id={`${idPrefix}-rrule`}
          value={values.recurrenceRule}
          disabled={readOnly}
          onChange={(e) => {
            onFieldChange('recurrenceRule', e.target.value);
            onClearFieldError('recurrenceRule');
          }}
          className={styles.textarea}
          rows={2}
          placeholder={recurrencePlaceholder}
          maxLength={2048}
          aria-invalid={fieldErrors.recurrenceRule ? true : undefined}
          aria-describedby={fieldErrors.recurrenceRule ? `${idPrefix}-rrule-err` : undefined}
        />
        {recurrenceHint ? <span className={styles.fieldHint}>{recurrenceHint}</span> : null}
        {fieldErrors.recurrenceRule ? (
          <span id={`${idPrefix}-rrule-err`} className={styles.fieldError} role="alert">
            {fieldErrors.recurrenceRule}
          </span>
        ) : null}
      </label>

      <label className={styles.field} htmlFor={`${idPrefix}-scheduled`}>
        <span className={styles.fieldLabel}>{t('form.startDateTime')}</span>
        <input
          id={`${idPrefix}-scheduled`}
          type="datetime-local"
          value={values.scheduledAtLocal}
          disabled={readOnly}
          onChange={(e) => {
            onFieldChange('scheduledAtLocal', e.target.value);
            onClearFieldError('scheduledAt');
          }}
          className={styles.input}
          aria-invalid={fieldErrors.scheduledAt ? true : undefined}
          aria-describedby={fieldErrors.scheduledAt ? `${idPrefix}-scheduled-err` : undefined}
        />
        {fieldErrors.scheduledAt ? (
          <span id={`${idPrefix}-scheduled-err`} className={styles.fieldError} role="alert">
            {fieldErrors.scheduledAt}
          </span>
        ) : null}
      </label>

      {showEndAt ? (
        <label className={styles.field} htmlFor={`${idPrefix}-end`}>
          <span className={styles.fieldLabel}>{t('form.endDateTime')}</span>
          <span className={styles.fieldHint}>{t('form.endDateHint')}</span>
          <input
            id={`${idPrefix}-end`}
            type="datetime-local"
            value={values.endAtLocal}
            disabled={readOnly}
            onChange={(e) => {
              onFieldChange('endAtLocal', e.target.value);
              onClearFieldError('endAt');
            }}
            className={styles.input}
            aria-invalid={fieldErrors.endAt ? true : undefined}
            aria-describedby={fieldErrors.endAt ? `${idPrefix}-end-err` : undefined}
          />
          {fieldErrors.endAt ? (
            <span id={`${idPrefix}-end-err`} className={styles.fieldError} role="alert">
              {fieldErrors.endAt}
            </span>
          ) : null}
        </label>
      ) : null}

      {(scheduleConflictHint || scheduleConflictFetchFailed || scheduleConflictChecking) ? (
        <ScheduleConflictBanner
          hint={scheduleConflictHint ?? null}
          checking={scheduleConflictChecking}
          fetchFailed={scheduleConflictFetchFailed}
          withBottomMargin
          overrideChecked={scheduleConflictOverride}
          readOnly={readOnly}
          {...(onScheduleConflictOverrideChange
            ? { onOverrideChange: onScheduleConflictOverrideChange }
            : {})}
        />
      ) : null}

      {beforeParticipants}

      <label className={styles.field} htmlFor={`${idPrefix}-participants`}>
        <span className={styles.fieldLabel}>{resolvedParticipantLabel}</span>
        {useInputComponentForParticipants ? (
          <Input
            id={`${idPrefix}-participants`}
            type="number"
            min={0}
            value={String(values.participantCount)}
            disabled={readOnly}
            onChange={(e) => {
              onFieldChange('participantCount', Math.max(0, parseInt(e.target.value, 10) || 0));
              onClearFieldError('participantCount');
            }}
            className={styles.inputNumber}
            aria-invalid={fieldErrors.participantCount ? true : undefined}
            aria-describedby={
              fieldErrors.participantCount ? `${idPrefix}-participants-err` : undefined
            }
          />
        ) : (
          <input
            id={`${idPrefix}-participants`}
            type="number"
            min={0}
            value={values.participantCount}
            disabled={readOnly}
            onChange={(e) => {
              onFieldChange('participantCount', Math.max(0, parseInt(e.target.value, 10) || 0));
              onClearFieldError('participantCount');
            }}
            className={styles.input}
            aria-invalid={fieldErrors.participantCount ? true : undefined}
            aria-describedby={
              fieldErrors.participantCount ? `${idPrefix}-participants-err` : undefined
            }
          />
        )}
        {fieldErrors.participantCount ? (
          <span id={`${idPrefix}-participants-err`} className={styles.fieldError} role="alert">
            {fieldErrors.participantCount}
          </span>
        ) : null}
      </label>

      {afterParticipants}
    </>
  );
}
