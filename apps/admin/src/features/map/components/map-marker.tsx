'use client';

import { memo, useCallback, useMemo } from 'react';
import { Marker } from 'react-leaflet';
import L from 'leaflet';
import type { SiteMapRow } from '../data/map-adapter';
import styles from './sites-map.module.css';

const STATUS_CLASS: Record<string, string> = {
  REPORTED: styles.markerReported,
  VERIFIED: styles.markerVerified,
  CLEANUP_SCHEDULED: styles.markerCleanupScheduled,
  IN_PROGRESS: styles.markerInProgress,
  CLEANED: styles.markerCleaned,
  DISPUTED: styles.markerDisputed,
};

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function createMarkerIcon(site: SiteMapRow, selected: boolean): L.DivIcon {
  const statusClass = STATUS_CLASS[site.status] ?? styles.markerDefault;
  const reportCount = site.reportCount > 0 ? site.reportCount : '';
  const pinClass = selected ? `${styles.markerPin} ${statusClass} ${styles.markerPinSelected}` : `${styles.markerPin} ${statusClass}`;

  const safeAriaLabel = escapeHtml(`Site ${site.id}, ${site.reportCount} reports`);
  return L.divIcon({
    className: styles.markerIcon,
    html: `<span class="${pinClass}" aria-label="${safeAriaLabel}">${reportCount}</span>`,
    iconSize: [24, 24],
    iconAnchor: [12, 12],
  });
}

type MapMarkerProps = {
  site: SiteMapRow;
  selected: boolean;
  onClick: () => void;
};

export const MapMarker = memo(function MapMarker({ site, selected, onClick }: MapMarkerProps) {
  const icon = useMemo(
    () => createMarkerIcon(site, selected),
    [site.id, site.status, site.reportCount, selected],
  );

  const handleClick = useCallback(
    (e: { originalEvent: Event }) => {
      L.DomEvent.stopPropagation(e.originalEvent);
      onClick();
    },
    [onClick],
  );

  return (
    <Marker
      position={[site.latitude, site.longitude]}
      icon={icon}
      eventHandlers={{ click: handleClick }}
      keyboard={true}
    />
  );
});
