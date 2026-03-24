'use client';

import Link from 'next/link';
import Image from 'next/image';
import { motion, useReducedMotion } from 'framer-motion';
import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react';
import { Icon } from '@/components/ui';
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

function formatDistanceKm(km: number | undefined): string | null {
  if (km == null || Number.isNaN(km)) return null;
  if (km < 1) return `${Math.round(km * 1000)} m from map center`;
  return `${km < 10 ? km.toFixed(1) : Math.round(km)} km from map center`;
}

function humanizeCategory(raw: string | null | undefined): string | null {
  if (!raw?.trim()) return null;
  return raw.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
}

type SitePreviewPanelProps = {
  site: SiteMapRow;
  onClose: () => void;
};

export function SitePreviewPanel({ site, onClose }: SitePreviewPanelProps) {
  const reduceMotion = useReducedMotion();
  const closeRef = useRef<HTMLButtonElement>(null);
  const [photoIndex, setPhotoIndex] = useState(0);
  const [descExpanded, setDescExpanded] = useState(false);
  const [copyAnnounced, setCopyAnnounced] = useState('');
  const [heroFailed, setHeroFailed] = useState(false);
  const [narrowSheet, setNarrowSheet] = useState(
    () => typeof window !== 'undefined' && window.matchMedia('(max-width: 920px)').matches,
  );

  const media = site.latestReportMediaUrls?.filter(Boolean) ?? [];
  const hasMedia = media.length > 0;
  const safePhotoIndex = hasMedia ? Math.min(photoIndex, media.length - 1) : 0;
  const currentPhoto = hasMedia ? media[safePhotoIndex] : null;

  const description = [site.description?.trim(), site.latestReportDescription?.trim()]
    .filter(Boolean)
    .join('\n\n')
    .trim();
  const longDescription = description.length > 280;
  const badgeClass = BADGE_CLASS[site.status] ?? styles.badgeDefault;
  const created = new Date(site.createdAt).toLocaleString(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
  const updated =
    site.updatedAt != null
      ? new Date(site.updatedAt).toLocaleString(undefined, {
          dateStyle: 'medium',
          timeStyle: 'short',
        })
      : null;
  const latestReportAt =
    site.latestReportCreatedAt != null
      ? new Date(site.latestReportCreatedAt).toLocaleString(undefined, {
          dateStyle: 'medium',
          timeStyle: 'short',
        })
      : null;
  const categoryLabel = humanizeCategory(site.latestReportCategory);
  const distanceLabel = formatDistanceKm(site.distanceKm);

  const latStr = site.latitude.toFixed(5);
  const lngStr = site.longitude.toFixed(5);
  const coordClipboard = `${latStr}, ${lngStr}`;

  const appleMapsHref = `https://maps.apple.com/?ll=${site.latitude},${site.longitude}&q=${encodeURIComponent(`Site ${site.id.slice(0, 8)}`)}`;
  const googleMapsHref = `https://www.google.com/maps/search/?api=1&query=${site.latitude},${site.longitude}`;

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

  const copyCoords = useCallback(async () => {
    try {
      await navigator.clipboard.writeText(coordClipboard);
      setCopyAnnounced('Coordinates copied');
      window.setTimeout(() => setCopyAnnounced(''), 2500);
    } catch {
      setCopyAnnounced('Could not copy');
      window.setTimeout(() => setCopyAnnounced(''), 2500);
    }
  }, [coordClipboard]);

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
        aria-label="Close site details"
        onClick={onClose}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        transition={reduceMotion ? { duration: 0 } : { duration: 0.28 }}
      />

      <motion.aside
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
            <p className={styles.kicker}>Pollution site</p>
            <h2 id="site-preview-title" className={styles.title}>
              Site #{site.id.slice(0, 8).toUpperCase()}
            </h2>
            <p className={styles.subtitle}>
              <span>Created {created}</span>
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
            aria-label="Close"
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
                <span>{hasMedia ? 'Image unavailable' : 'No photos yet'}</span>
              </div>
            )}
            <span className={styles.heroBadge}>{site.reportCount} report{site.reportCount !== 1 ? 's' : ''}</span>
          </div>

          {media.length > 1 ? (
            <div className={styles.thumbRow}>
              {media.map((url, i) => (
                <button
                  key={url}
                  type="button"
                  className={`${styles.thumb} ${i === safePhotoIndex ? styles.thumbSelected : ''}`}
                  onClick={() => {
                    setPhotoIndex(i);
                    setHeroFailed(false);
                  }}
                  aria-label={`Show photo ${i + 1} of ${media.length}`}
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
            <span className={`${styles.badge} ${badgeClass}`}>{formatStatus(site.status)}</span>
            {categoryLabel ? <span className={styles.metaMuted}>{categoryLabel}</span> : null}
            {distanceLabel ? <span className={styles.metaMuted}>{distanceLabel}</span> : null}
          </div>

          {description ? (
            <div className={styles.detailGroup}>
              <p className={styles.detailLabel}>Details</p>
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
                  {descExpanded ? 'Show less' : 'Show more'}
                </button>
              ) : null}
            </div>
          ) : null}

          <div className={styles.detailGroup}>
            <p className={styles.detailLabel}>Facts</p>
            <div className={styles.rows}>
              <div className={styles.row}>
                <span className={styles.rowLabel}>Coordinates</span>
                <span className={styles.rowValue}>
                  <span className={styles.rowValueMono}>
                    {latStr}, {lngStr}
                  </span>
                  <button
                    type="button"
                    className={styles.iconBtn}
                    onClick={() => void copyCoords()}
                    aria-label="Copy coordinates"
                  >
                    <Icon name="copy" size={16} />
                  </button>
                </span>
              </div>
              {updated ? (
                <div className={styles.row}>
                  <span className={styles.rowLabel}>Last updated</span>
                  <span className={styles.rowValue}>{updated}</span>
                </div>
              ) : null}
              {latestReportAt ? (
                <div className={styles.row}>
                  <span className={styles.rowLabel}>Latest report</span>
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
              Apple Maps
            </a>
            <a
              className={styles.mapsLink}
              href={googleMapsHref}
              target="_blank"
              rel="noopener noreferrer"
            >
              <Icon name="external-link" size={14} />
              Google Maps
            </a>
          </div>
        </div>

        <footer className={styles.footer}>
          <Link href={`/dashboard/sites/${site.id}`} className={styles.linkPrimary}>
            View full site
          </Link>
          <div className={styles.pillRow}>
            <Link href={`/dashboard/reports?siteId=${site.id}`} className={styles.linkSecondary}>
              Reports
            </Link>
            <Link href={`/dashboard/events/new?siteId=${site.id}`} className={styles.linkSecondary}>
              New event
            </Link>
          </div>
        </footer>
      </motion.aside>
    </motion.div>
  );
}
