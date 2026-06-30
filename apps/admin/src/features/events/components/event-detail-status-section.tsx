'use client';

import { useLocale, useTranslations } from 'next-intl';
import type { CleanupEventDetail } from '@/features/events/data/events-adapter';
import { formatEventAdminDateTime } from '@/features/events/lib/event-admin-datetime';
import styles from './event-detail.module.css';

type EventDetailStatusSectionProps = {
  event: CleanupEventDetail;
  isCompleted: boolean;
  moderationStatus: string;
  declineReason?: string | null;
};

export function EventDetailStatusSection({
  event,
  isCompleted,
  moderationStatus,
  declineReason = null,
}: EventDetailStatusSectionProps) {
  const locale = useLocale();
  const tDetail = useTranslations('events.detail');
  const tTable = useTranslations('events.table');

  return (
    <section className={styles.sectionCard}>
      <span className={styles.sectionLabel}>{tDetail('eventStatus')}</span>
      <div className={styles.statusRow}>
        <span className={isCompleted ? styles.statusCompleted : styles.statusUpcoming}>
          {isCompleted ? tTable('completed') : tTable('upcoming')}
        </span>
        <span className={styles.lifecyclePill}>{event.lifecycleStatus}</span>
        <span
          className={
            moderationStatus === 'PENDING'
              ? styles.moderationPending
              : moderationStatus === 'DECLINED'
                ? styles.moderationDeclined
                : styles.moderationApproved
          }
        >
          {moderationStatus}
        </span>
      </div>
      {moderationStatus === 'DECLINED' && declineReason ? (
        <p className={styles.declineReasonBox} role="note">
          <span className={styles.metaLabel}>{tDetail('declineReasonLabel')}</span>
          <span>{declineReason}</span>
        </p>
      ) : null}
      <h2 className={styles.eventTitle}>{event.title}</h2>
      {event.description ? <p className={styles.eventDescription}>{event.description}</p> : null}
      {event.recurrenceRule ? (
        <p className={styles.recurrenceReadonly}>
          <span className={styles.metaLabel}>{tDetail('recurrence')}</span>
          <code className={styles.rruleCode}>{event.recurrenceRule}</code>
        </p>
      ) : null}
      <div className={styles.metaRow}>
        <div className={styles.metaItem}>
          <span className={styles.metaLabel}>{tTable('scheduled')}</span>
          <span className={styles.metaValue}>{formatEventAdminDateTime(event.scheduledAt, locale)}</span>
        </div>
        {event.completedAt ? (
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>{tTable('completed')}</span>
            <span className={styles.metaValue}>{formatEventAdminDateTime(event.completedAt, locale)}</span>
          </div>
        ) : null}
        <div className={styles.metaItem}>
          <span className={styles.metaLabel}>{tTable('participants')}</span>
          <span className={styles.metaValue}>{event.participantCount}</span>
        </div>
      </div>
    </section>
  );
}
