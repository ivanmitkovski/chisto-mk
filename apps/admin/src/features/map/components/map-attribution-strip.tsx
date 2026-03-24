'use client';

import styles from './sites-map.module.css';

/**
 * Tile providers require visible attribution; kept as UI chrome (not a map tile watermark).
 */
export function MapAttributionStrip() {
  return (
    <div className={styles.mapAttribution}>
      <span className={styles.mapAttributionLabel}>Map</span>
      <a
        className={styles.mapAttributionLink}
        href="https://www.openstreetmap.org/copyright"
        target="_blank"
        rel="noopener noreferrer"
      >
        OpenStreetMap
      </a>
      <span className={styles.mapAttributionSep} aria-hidden>
        ·
      </span>
      <a
        className={styles.mapAttributionLink}
        href="https://carto.com/attributions"
        target="_blank"
        rel="noopener noreferrer"
      >
        CARTO
      </a>
    </div>
  );
}
