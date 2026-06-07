'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import type { CheckInRiskSignalRow } from '../data/events-adapter';
import {
  formatRiskSignalDistance,
  formatRiskSignalLabel,
  formatRiskSignalResolution,
  riskSignalMapLinks,
} from '../lib/risk-signal-display';
import styles from './risk-signals-page.module.css';

export function RiskSignalDetailsCell({ row }: { row: CheckInRiskSignalRow }) {
  const t = useTranslations('events.riskSignals');
  const riskT = (
    key: 'signalFarFromSite' | 'resolutionDismissed' | 'resolutionResolved' | 'resolutionClosed',
  ) => t(key);

  const distance = formatRiskSignalDistance(row.metadata, (key, values) => t(key, values));
  const mapLinks = riskSignalMapLinks(row.metadata);
  const resolution = formatRiskSignalResolution(row, riskT);

  return (
    <div className={styles.signalDetails}>
      <p className={styles.signalTitle}>{formatRiskSignalLabel(row.signalType, riskT)}</p>
      {distance ? <p className={styles.signalMeta}>{distance}</p> : null}
      {resolution ? (
        <p className={styles.signalResolution} aria-label={t('resolutionAria')}>
          {resolution}
        </p>
      ) : null}
      {mapLinks.siteGoogle || mapLinks.checkInGoogle ? (
        <div className={styles.signalMapLinks}>
          {mapLinks.siteGoogle ? (
            <a href={mapLinks.siteGoogle} target="_blank" rel="noopener noreferrer" className={styles.actionLink}>
              {t('siteGoogle')}
            </a>
          ) : null}
          {mapLinks.checkInGoogle ? (
            <a href={mapLinks.checkInGoogle} target="_blank" rel="noopener noreferrer" className={styles.actionLink}>
              {t('checkInGoogle')}
            </a>
          ) : null}
        </div>
      ) : null}
    </div>
  );
}

export function RiskSignalEventCell({ row }: { row: CheckInRiskSignalRow }) {
  return (
    <Link href={`/dashboard/events/${row.eventId}`} className={styles.actionLink}>
      {row.eventTitle || row.eventId}
    </Link>
  );
}
