import type { CheckInRiskSignalRow } from '../data/events-adapter';
import { buildAppleMapsUrl, buildGoogleMapsUrl } from './map-links';

type FarFromSiteMetadata = {
  distanceMeters?: number;
  thresholdMeters?: number;
  checkInLatitude?: number;
  checkInLongitude?: number;
  siteLatitude?: number;
  siteLongitude?: number;
};

type RiskSignalTranslate = (
  key: 'signalFarFromSite' | 'resolutionDismissed' | 'resolutionResolved' | 'resolutionClosed',
) => string;

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value == null || typeof value !== 'object' || Array.isArray(value)) {
    return null;
  }
  return value as Record<string, unknown>;
}

function readFarFromSiteMetadata(metadata: unknown): FarFromSiteMetadata {
  const record = asRecord(metadata);
  if (!record) {
    return {};
  }
  const num = (key: keyof FarFromSiteMetadata) => {
    const v = record[key as string];
    return typeof v === 'number' && Number.isFinite(v) ? v : undefined;
  };
  const result: FarFromSiteMetadata = {};
  for (const key of [
    'distanceMeters',
    'thresholdMeters',
    'checkInLatitude',
    'checkInLongitude',
    'siteLatitude',
    'siteLongitude',
  ] as const) {
    const value = num(key);
    if (value !== undefined) {
      result[key] = value;
    }
  }
  return result;
}

export function formatRiskSignalLabel(signalType: string, t: RiskSignalTranslate): string {
  if (signalType === 'FAR_FROM_SITE') {
    return t('signalFarFromSite');
  }
  return signalType.replaceAll('_', ' ').toLowerCase();
}

type DistanceTranslate = (
  key: 'distanceFromSite' | 'distanceThreshold',
  values?: Record<string, string | number>,
) => string;

export function formatRiskSignalDistance(metadata: unknown, t?: DistanceTranslate): string | null {
  const { distanceMeters, thresholdMeters } = readFarFromSiteMetadata(metadata);
  if (distanceMeters == null) {
    return null;
  }
  const distance = Math.round(distanceMeters).toLocaleString();
  const base = t
    ? t('distanceFromSite', { distance })
    : `${distance} m from site`;
  const threshold =
    thresholdMeters != null
      ? t
        ? t('distanceThreshold', { threshold: Math.round(thresholdMeters) })
        : ` (threshold ${Math.round(thresholdMeters)} m)`
      : '';
  return `${base}${threshold}`;
}

export function riskSignalMapLinks(metadata: unknown): {
  siteGoogle?: string;
  siteApple?: string;
  checkInGoogle?: string;
  checkInApple?: string;
} {
  const meta = readFarFromSiteMetadata(metadata);
  const links: ReturnType<typeof riskSignalMapLinks> = {};
  if (meta.siteLatitude != null && meta.siteLongitude != null) {
    links.siteGoogle = buildGoogleMapsUrl(meta.siteLatitude, meta.siteLongitude);
    links.siteApple = buildAppleMapsUrl(meta.siteLatitude, meta.siteLongitude);
  }
  if (meta.checkInLatitude != null && meta.checkInLongitude != null) {
    links.checkInGoogle = buildGoogleMapsUrl(meta.checkInLatitude, meta.checkInLongitude);
    links.checkInApple = buildAppleMapsUrl(meta.checkInLatitude, meta.checkInLongitude);
  }
  return links;
}

export function formatRiskSignalResolution(
  row: CheckInRiskSignalRow,
  t: RiskSignalTranslate,
): string | null {
  if (!row.resolvedAt) {
    return null;
  }
  if (row.resolutionAction === 'dismiss') {
    return t('resolutionDismissed');
  }
  if (row.resolutionAction === 'resolve') {
    return t('resolutionResolved');
  }
  return t('resolutionClosed');
}
