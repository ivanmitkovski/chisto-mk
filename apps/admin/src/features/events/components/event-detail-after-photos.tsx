'use client';

import Link from 'next/link';
import Image from 'next/image';
import { useTranslations } from 'next-intl';
import styles from './event-detail.module.css';

type EventDetailAfterPhotosProps = {
  afterImageUrls: string[];
};

export function EventDetailAfterPhotos({ afterImageUrls }: EventDetailAfterPhotosProps) {
  const t = useTranslations('events');
  const tDetail = useTranslations('events.detail');

  if (afterImageUrls.length === 0) {
    return null;
  }

  return (
    <section className={styles.sectionCard} aria-label={t('afterPhotosAria')}>
      <span className={styles.sectionLabel}>{tDetail('afterPhotos')}</span>
      <p className={styles.fieldHint}>{tDetail('afterPhotosHint')}</p>
      <ul className={styles.afterPhotoGrid}>
        {afterImageUrls.map((url) => (
          <li key={url}>
            <a href={url} target="_blank" rel="noopener noreferrer" className={styles.afterPhotoLink}>
              <Image
                src={url}
                alt=""
                width={240}
                height={180}
                className={styles.afterPhoto}
                sizes="240px"
              />
            </a>
          </li>
        ))}
      </ul>
    </section>
  );
}

type EventDetailContextProps = {
  event: {
    id: string;
    organizer?: { id: string; displayName: string; email: string } | null;
    parentEventId?: string | null;
    recurrenceIndex?: number | null;
    seriesChildrenCount?: number;
    recurrenceRule?: string | null;
  };
};

export function EventDetailContextSection({ event }: EventDetailContextProps) {
  const t = useTranslations('events');
  const tDetail = useTranslations('events.detail');

  const hasOrganizer = !!event.organizer;
  const hasSeries =
    !!event.parentEventId ||
    (event.seriesChildrenCount != null && event.seriesChildrenCount > 0) ||
    !!event.recurrenceRule;

  if (!hasOrganizer && !hasSeries) {
    return null;
  }

  return (
    <section className={styles.sectionCard} aria-label={t('eventContextAria')}>
      <span className={styles.sectionLabel}>{tDetail('context')}</span>
      {hasOrganizer && event.organizer ? (
        <p className={styles.fieldHint}>
          {tDetail('organizer')}:{' '}
          <Link href={`/dashboard/users/${event.organizer.id}`} className={styles.siteLink}>
            {event.organizer.displayName}
          </Link>
          {' · '}
          {event.organizer.email}
        </p>
      ) : null}
      {event.parentEventId ? (
        <p className={styles.fieldHint}>
          {tDetail('partOfSeries')}{' '}
          <Link href={`/dashboard/events/${event.parentEventId}`} className={styles.siteLink}>
            {event.parentEventId}
          </Link>
          {event.recurrenceIndex != null
            ? ` ${tDetail('occurrence', { index: event.recurrenceIndex + 1 })}`
            : null}
        </p>
      ) : null}
      {!event.parentEventId && event.recurrenceRule ? (
        <p className={styles.fieldHint}>
          {tDetail('recurrenceRule')} <code className={styles.inlineCode}>{event.recurrenceRule}</code>
        </p>
      ) : null}
      {event.seriesChildrenCount != null && event.seriesChildrenCount > 0 ? (
        <p className={styles.fieldHint}>
          {tDetail('childEvents', { count: event.seriesChildrenCount })}
        </p>
      ) : null}
    </section>
  );
}
