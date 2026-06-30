'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { buildAppleMapsUrl, buildGoogleMapsUrl } from '@/features/events/lib/map-links';
import styles from './create-event-form.module.css';

export type CreateEventSitePreview = {
  id: string;
  latitude: number;
  longitude: number;
  description: string | null;
  status: string;
  reportCount: number;
};

export function CreateEventSitePreviewPanel({ site }: { site: CreateEventSitePreview }) {
  const t = useTranslations('events');
  const tCommon = useTranslations('common');

  return (
    <section className={styles.sitePreviewCard} aria-label={t('sitePreviewAria')}>
      <span className={styles.sectionLabel}>{t('sitePreview.title')}</span>
      <p className={styles.hint}>
        {site.latitude.toFixed(6)}, {site.longitude.toFixed(6)} · {site.status} ·{' '}
        {t('sitePreview.reportCount', { count: site.reportCount })}
      </p>
      {site.description ? <p className={styles.sitePreviewDesc}>{site.description}</p> : null}
      <div className={styles.sitePreviewLinks}>
        <a href={buildGoogleMapsUrl(site.latitude, site.longitude)} target="_blank" rel="noopener noreferrer">
          {tCommon('googleMaps')}
        </a>
        <a href={buildAppleMapsUrl(site.latitude, site.longitude)} target="_blank" rel="noopener noreferrer">
          {tCommon('appleMaps')}
        </a>
        <Link href={`/dashboard/sites/${site.id}`}>{t('create.viewSite')}</Link>
      </div>
    </section>
  );
}
