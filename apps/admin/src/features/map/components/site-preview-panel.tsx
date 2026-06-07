'use client';

import Link from 'next/link';
import Image from 'next/image';
import { motion, useReducedMotion } from 'framer-motion';
import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Icon } from '@/components/ui';
import { useAdminBcp47Locale } from '@/lib/i18n';
import type { SiteMapRow } from '../data/map-adapter';
import styles from './site-preview-panel.module.css';

const BADGE_CLASS: Record<string, string> = {
  REPORTED: styles.badgeReported,
  VERIFIED: styles.badgeVerified,
  CLEANUP_SCHEDULED: styles.badgeScheduled,
  IN_PROGRESS: styles.badgeInProgress,
  CLEANED: styles.badgeCleaned,
  DISPUTED: styles.badgeDisputed,
};

function formatStatus(status: string): string {
  return status.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase());
}

function formatDistanceKm(
  km: number | undefined,
  t: (key: 'distanceMeters' | 'distanceKm', values: { distance: string | number }) => string,
): string | null {
  if (km == null || Number.isNaN(km)) return null;
  if (km < 1) return t('distanceMeters', { distance: Math.round(km * 1000) });
  return t('distanceKm', { distance: km < 10 ? km.toFixed(1) : Math.round(km) });
}

function humanizeCategory(raw: string | null | undefined): string | null {
  if (!raw?.trim()) return null;
  return raw.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
}

type SitePreviewPanelProps = {
  site: SiteMapRow;
  onClose: () => void;
};

const FOCUSABLE_SELECTOR =
  'a[href], button:not([disabled]), textarea, input, select, [tabindex]:not([tabindex="-1"])';

const STATUS_LABEL_KEY_BY_VALUE: Record<string, string> = {
  REPORTED: 'statusFilters.reported',
  VERIFIED: 'statusFilters.verified',
  CLEANUP_SCHEDULED: 'statusFilters.cleanupScheduled',
  IN_PROGRESS: 'statusFilters.inProgress',
  CLEANED: 'statusFilters.cleaned',
  DISPUTED: 'statusFilters.disputed',
};

export function SitePreviewPanel({ site, onClose }: SitePreviewPanelProps) {
  const t = useTranslations('map');
  const tPreview = useTranslations('map.preview');
  const tCommon = useTranslations('common');
  const locale = useAdminBcp47Locale();
  const reduceMotion = useReducedMotion();
  const sheetRef = useRef<HTMLElement | null>(null);
  const closeRef = useRef<HTMLButtonElement>(null);
  const [photoIndex, setPhotoIndex] = useState(0);
  const [descExpanded, setDescExpanded] = useState(false);
  const [copyAnnounced, setCopyAnnounced] = useState('');
  const [heroFailed, setHeroFailed] = useState(false);
  const [narrowSheet, setNarrowSheet] = useState(
    () => typeof window !== 'undefined' && window.matchMedia('(max-width: 920px)').matches,
  );

  const media: string[] = ((site.latestReportMediaUrls ?? []) as unknown[]).filter(
    (url): url is string => typeof url === 'string' && url.length > 0,
  );
  const hasMedia = media.length > 0;
  const safePhotoIndex = hasMedia ? Math.min(photoIndex, media.length - 1) : 0;
  const currentPhoto = hasMedia ? media[safePhotoIndex] : null;

  const description = [site.description?.trim(), site.latestReportDescription?.trim()]
    .filter(Boolean)
    .join('\n\n')
    .trim();
  const longDescription = description.length > 280;
  const badgeClass = BADGE_CLASS[site.status] ?? styles.badgeDefault;
  const created = new Date(site.createdAt).toLocaleString(locale, {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
  const updated =
    site.updatedAt != null
      ? new Date(site.updatedAt).toLocaleString(locale, {
          dateStyle: 'medium',
          timeStyle: 'short',
        })
      : null;
  const latestReportAt =
    site.latestReportCreatedAt != null
      ? new Date(site.latestReportCreatedAt).toLocaleString(locale, {
          dateStyle: 'medium',
          timeStyle: 'short',
        })
      : null;
  const categoryLabel = humanizeCategory(site.latestReportCategory);
  const distanceLabel = formatDistanceKm(site.distanceKm, (key, values) => tPreview(key, values));
  const isCluster = site.isCluster === true;

  const latStr = site.latitude.toFixed(5);
  const lngStr = site.longitude.toFixed(5);
  const coordClipboard = `${latStr}, ${lngStr}`;

  const appleMapsHref = `https://maps.apple.com/?ll=${site.latitude},${site.longitude}&q=${encodeURIComponent(`Site ${site.id.slice(0, 8)}`)}`;
  const googleMapsHref = `https://www.google.com/maps/search/?api=1&query=${site.latitude},${site.longitude}`;
  const statusLabel = (() => {
    const labelKey = STATUS_LABEL_KEY_BY_VALUE[site.status];
    return labelKey ? t(labelKey) : formatStatus(site.status);
  })();

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') onClose();
    }
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [onClose]);

  useLayoutEffect(() => {
    const mq = window.matchMedia('(max-width: 920px)');
    const apply = () => setNarrowSheet(mq.matches);
    apply();
    mq.addEventListener('change', apply);
    return () => mq.removeEventListener('change', apply);
  }, []);

  useEffect(() => {
    setPhotoIndex(0);
    setDescExpanded(false);
    setHeroFailed(false);
  }, [site.id]);

  useEffect(() => {
    const t = window.setTimeout(() => closeRef.current?.focus(), 0);
    return () => window.clearTimeout(t);
  }, []);

  useEffect(() => {
    const root = sheetRef.current;
    if (!root) {
      return;
    }
    const getFocusable = (): HTMLElement[] =>
      Array.from(root.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR));

    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key !== 'Tab') {
        return;
      }
      const nodes = getFocusable();
      if (nodes.length === 0) {
        return;
      }
      const first = nodes[0];
      const last = nodes[nodes.length - 1];
      const active = document.activeElement as HTMLElement | null;
      if (e.shiftKey) {
        if (active === first || !root.contains(active)) {
          e.preventDefault();
          last.focus();
        }
      } else if (active === last) {
        e.preventDefault();
        first.focus();
      }
    };

    root.addEventListener('keydown', onKeyDown);
    return () => root.removeEventListener('keydown', onKeyDown);
  }, [site.id]);

  const copyCoords = useCallback(async () => {
    try {
      await navigator.clipboard.writeText(coordClipboard);
      setCopyAnnounced(tPreview('coordsCopied'));
      window.setTimeout(() => setCopyAnnounced(''), 2500);
    } catch {
      setCopyAnnounced(tPreview('copyFailed'));
      window.setTimeout(() => setCopyAnnounced(''), 2500);
    }
  }, [coordClipboard, tPreview]);

  const transition = reduceMotion
    ? { duration: 0 }
    : { duration: 0.34, ease: [0.22, 1, 0.36, 1] as const };

  return (
    <motion.div
      className={styles.overlayRoot}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={reduceMotion ? { duration: 0 } : { duration: 0.22 }}
    >
      <motion.button
        type="button"
        className={styles.scrim}
        aria-label={tPreview('closeSiteDetails')}
        onClick={onClose}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        transition={reduceMotion ? { duration: 0 } : { duration: 0.28 }}
      />

      <motion.aside
        ref={sheetRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby="site-preview-title"
        className={styles.sheet}
        initial={
          reduceMotion
            ? { opacity: 0 }
            : narrowSheet
              ? { y: 48, opacity: 0, scale: 0.98 }
              : { x: 56, opacity: 0, scale: 0.97 }
        }
        animate={
          reduceMotion
            ? { opacity: 1 }
            : narrowSheet
              ? { y: 0, opacity: 1, scale: 1 }
              : { x: 0, opacity: 1, scale: 1, filter: 'blur(0px)' }
        }
        exit={
          reduceMotion
            ? { opacity: 0 }
            : narrowSheet
              ? { y: 36, opacity: 0, scale: 0.99 }
              : { x: 40, opacity: 0, scale: 0.98 }
        }
        transition={transition}
      >
        <div className={styles.dragHint} aria-hidden />
        <span className={styles.liveRegion} role="status" aria-live="polite">
          {copyAnnounced}
        </span>

        <header className={styles.header}>
          <div className={styles.headerText}>
            <p className={styles.kicker}>{isCluster ? tPreview('siteCluster') : tPreview('pollutionSite')}</p>
            <h2 id="site-preview-title" className={styles.title}>
              {isCluster
                ? tPreview('clusterTitle', { count: site.reportCount })
                : tPreview('siteTitle', { id: site.id.slice(0, 8).toUpperCase() })}
            </h2>
            <p className={styles.subtitle}>
              <span>
                {isCluster ? tPreview('zoomToInspect') : tPreview('created', { date: created })}
              </span>
              {site.latestReportNumber ? (
                <>
                  <span aria-hidden>·</span>
                  <span>{site.latestReportNumber}</span>
                </>
              ) : null}
            </p>
          </div>
          <button
            ref={closeRef}
            type="button"
            className={styles.closeBtn}
            onClick={onClose}
            aria-label={tPreview('close')}
          >
            <Icon name="x" size={18} />
          </button>
        </header>

        <div className={styles.mediaSection}>
          <div className={styles.hero}>
            {hasMedia && currentPhoto && !heroFailed ? (
              <>
                <Image
                  src={currentPhoto}
                  alt=""
                  fill
                  className={styles.heroImage}
                  sizes="(max-width: 920px) 96vw, 392px"
                  onError={() => setHeroFailed(true)}
                  priority
                />
              </>
            ) : (
              <div className={styles.heroFallback}>
                <Icon name="location" size={28} />
                <span>{hasMedia ? tPreview('imageUnavailable') : tPreview('noPhotos')}</span>
              </div>
            )}
            <span className={styles.heroBadge}>{tPreview('reportCount', { count: site.reportCount })}</span>
          </div>

          {media.length > 1 ? (
            <div className={styles.thumbRow}>
              {media.map((url: string, i: number) => (
                <button
                  key={url}
                  type="button"
                  className={`${styles.thumb} ${i === safePhotoIndex ? styles.thumbSelected : ''}`}
                  onClick={() => {
                    setPhotoIndex(i);
                    setHeroFailed(false);
                  }}
                  aria-label={tPreview('showPhoto', { index: i + 1, total: media.length })}
                >
                  <Image
                    src={url}
                    alt=""
                    width={52}
                    height={52}
                    className={styles.thumbImage}
                  />
                </button>
              ))}
            </div>
          ) : null}
        </div>

        <div className={styles.body}>
          <div className={styles.statusRow}>
            <span className={`${styles.badge} ${badgeClass}`}>{statusLabel}</span>
            {categoryLabel ? <span className={styles.metaMuted}>{categoryLabel}</span> : null}
            {distanceLabel ? <span className={styles.metaMuted}>{distanceLabel}</span> : null}
          </div>

          {description ? (
            <div className={styles.detailGroup}>
              <p className={styles.detailLabel}>{tPreview('details')}</p>
              <p
                className={`${styles.detailText} ${!descExpanded && longDescription ? styles.detailTextClamp : ''}`}
              >
                {description}
              </p>
              {longDescription ? (
                <button
                  type="button"
                  className={styles.expandBtn}
                  onClick={() => setDescExpanded((v) => !v)}
                >
                  {descExpanded ? tCommon('showLess') : tCommon('viewAll')}
                </button>
              ) : null}
            </div>
          ) : null}

          <div className={styles.detailGroup}>
            <p className={styles.detailLabel}>{tPreview('facts')}</p>
            <div className={styles.rows}>
              <div className={styles.row}>
                <span className={styles.rowLabel}>{tPreview('coordinates')}</span>
                <span className={styles.rowValue}>
                  <span className={styles.rowValueMono}>
                    {latStr}, {lngStr}
                  </span>
                  <button
                    type="button"
                    className={styles.iconBtn}
                    onClick={() => void copyCoords()}
                    aria-label={tPreview('copyCoordinates')}
                  >
                    <Icon name="copy" size={16} />
                  </button>
                </span>
              </div>
              {updated ? (
                <div className={styles.row}>
                  <span className={styles.rowLabel}>{tPreview('lastUpdated')}</span>
                  <span className={styles.rowValue}>{updated}</span>
                </div>
              ) : null}
              {latestReportAt ? (
                <div className={styles.row}>
                  <span className={styles.rowLabel}>{tPreview('latestReport')}</span>
                  <span className={styles.rowValue}>{latestReportAt}</span>
                </div>
              ) : null}
            </div>
          </div>

          <div className={styles.mapsRow}>
            <a
              className={styles.mapsLink}
              href={appleMapsHref}
              target="_blank"
              rel="noopener noreferrer"
            >
              <Icon name="map" size={14} />
              {tCommon('appleMaps')}
            </a>
            <a
              className={styles.mapsLink}
              href={googleMapsHref}
              target="_blank"
              rel="noopener noreferrer"
            >
              <Icon name="external-link" size={14} />
              {tCommon('googleMaps')}
            </a>
          </div>
        </div>

        <footer className={styles.footer}>
          {isCluster ? (
            <span className={styles.linkPrimary}>{tPreview('zoomToView')}</span>
          ) : (
            <>
              <Link href={`/dashboard/sites/${site.id}`} className={styles.linkPrimary}>
                {tPreview('viewFullSite')}
              </Link>
              <div className={styles.pillRow}>
                <Link href={`/dashboard/sites/${site.id}`} className={styles.linkSecondary}>
                  {tPreview('viewTimeline')}
                </Link>
                <Link href={`/dashboard/reports?siteId=${site.id}`} className={styles.linkSecondary}>
                  {tPreview('reports')}
                </Link>
                <Link href={`/dashboard/events/new?siteId=${site.id}`} className={styles.linkSecondary}>
                  {tPreview('newEvent')}
                </Link>
              </div>
            </>
          )}
        </footer>
      </motion.aside>
    </motion.div>
  );
}
