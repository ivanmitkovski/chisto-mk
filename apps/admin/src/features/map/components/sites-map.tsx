'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { AnimatePresence } from 'framer-motion';
import { useRouter } from 'next/navigation';
import { MapContainer, TileLayer, useMap, useMapEvents } from 'react-leaflet';
import MarkerClusterGroup from 'react-leaflet-cluster';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import 'react-leaflet-cluster/dist/assets/MarkerCluster.css';
import 'react-leaflet-cluster/dist/assets/MarkerCluster.Default.css';
import { Spinner } from '@/components/ui';
import { MapAttributionStrip } from './map-attribution-strip';
import { MapMarker } from './map-marker';
import { MapToolbar } from './map-toolbar';
import { MapZoomControls } from './map-zoom-controls';
import { SitePreviewPanel } from './site-preview-panel';
import type { SiteMapRow } from '../data/map-adapter';
import { useSitesMap } from '../hooks/use-sites-map';
import { MACEDONIA_BOUNDS, MACEDONIA_CENTER, INITIAL_ZOOM } from '../map-constants';
import { CLUSTER_EXPAND_MIN_ZOOM, flyToClusterContents } from '../utils/map-cluster-navigation';
import styles from './sites-map.module.css';

const CARTODB_POSITRON =
  'https://{s}.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}{r}.png';
const DEBOUNCE_MS = 400;

function MapEventHandler({
  onMoveEnd,
}: {
  onMoveEnd: (center: [number, number], zoom: number) => void;
}) {
  useMapEvents({
    moveend: (e) => {
      const m = e.target;
      const c = m.getCenter();
      onMoveEnd([c.lat, c.lng], m.getZoom());
    },
    zoomend: (e) => {
      const m = e.target;
      const c = m.getCenter();
      onMoveEnd([c.lat, c.lng], m.getZoom());
    },
  });
  return null;
}

function MapClickHandler({ onClick }: { onClick: () => void }) {
  useMapEvents({
    click: () => onClick(),
  });
  return null;
}

function FitBoundsEffect({ trigger }: { trigger: number }) {
  const map = useMap();
  useEffect(() => {
    if (trigger <= 0) return;
    const bounds = L.latLngBounds(
      [MACEDONIA_BOUNDS.minLat, MACEDONIA_BOUNDS.minLng],
      [MACEDONIA_BOUNDS.maxLat, MACEDONIA_BOUNDS.maxLng],
    );
    const reducedMotion =
      typeof window !== 'undefined' &&
      window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
    map.flyToBounds(bounds, {
      padding: [40, 40],
      maxZoom: 9,
      duration: reducedMotion ? 0 : 0.55,
      easeLinearity: 0.22,
    });
  }, [map, trigger]);
  return null;
}

function createClusterCustomIcon(cluster: { getChildCount: () => number }) {
  const count = cluster.getChildCount();
  const size = count >= 100 ? 52 : count >= 25 ? 46 : 40;
  const tierClass =
    count >= 100 ? styles.clusterIconLarge : count >= 25 ? styles.clusterIconMedium : styles.clusterIconSmall;
  return L.divIcon({
    html: `<span class="${styles.clusterIcon} ${tierClass}" style="width:${size}px;height:${size}px;">${count}</span>`,
    className: styles.clusterIconWrap,
    iconSize: [size, size],
  });
}

type SitesClusterLayerProps = {
  sites: SiteMapRow[];
  selectedSiteId: string | null;
  setSelectedSiteId: (id: string | null) => void;
};

function SitesClusterLayer({ sites, selectedSiteId, setSelectedSiteId }: SitesClusterLayerProps) {
  const map = useMap();

  const onClusterClick = useCallback(
    (e: L.LeafletMouseEvent) => {
      flyToClusterContents(map, e.layer);
    },
    [map],
  );

  return (
    <MarkerClusterGroup
      chunkedLoading
      animate
      animateAddingMarkers
      spiderfyOnMaxZoom
      zoomToBoundsOnClick={false}
      showCoverageOnHover={false}
      maxClusterRadius={56}
      disableClusteringAtZoom={CLUSTER_EXPAND_MIN_ZOOM}
      iconCreateFunction={createClusterCustomIcon}
      onClick={onClusterClick}
    >
      {sites.map((site) => (
        <MapMarker
          key={site.id}
          site={site}
          selected={selectedSiteId === site.id}
          onClick={() => setSelectedSiteId(site.id === selectedSiteId ? null : site.id)}
        />
      ))}
    </MarkerClusterGroup>
  );
}

export function SitesMap() {
  const router = useRouter();
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [fitBoundsTrigger, setFitBoundsTrigger] = useState(0);

  const {
    statusFilter,
    selectedSiteId,
    selectedSite,
    sites,
    isLoading,
    isFetching,
    isError,
    refetch,
    setCenter,
    setZoom,
    updateView,
    setStatusFilter,
    setSelectedSiteId,
  } = useSitesMap();

  const handleMoveEnd = useCallback(
    (newCenter: [number, number], newZoom: number) => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
      debounceRef.current = setTimeout(() => {
        updateView(newCenter, newZoom);
        debounceRef.current = null;
      }, DEBOUNCE_MS);
    },
    [updateView],
  );

  const handleMapClick = useCallback(() => {
    setSelectedSiteId(null);
  }, [setSelectedSiteId]);

  const handleFitBounds = useCallback(() => {
    setFitBoundsTrigger((t) => t + 1);
    const newCenter: [number, number] = [
      (MACEDONIA_BOUNDS.minLat + MACEDONIA_BOUNDS.maxLat) / 2,
      (MACEDONIA_BOUNDS.minLng + MACEDONIA_BOUNDS.maxLng) / 2,
    ];
    setCenter(newCenter);
    setZoom(8);
    updateView(newCenter, 8);
  }, [setCenter, setZoom, updateView]);

  useEffect(() => {
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, []);

  return (
    <div className={styles.mapWrap}>
      <MapToolbar
        statusFilter={statusFilter}
        onStatusChange={setStatusFilter}
        onFitBounds={handleFitBounds}
        onRefresh={() => refetch()}
      />

      <MapContainer
        center={[...MACEDONIA_CENTER]}
        zoom={INITIAL_ZOOM}
        className={styles.map}
        zoomControl={false}
        scrollWheelZoom={true}
        wheelDebounceTime={100}
        wheelPxPerZoomLevel={120}
        maxBounds={[
          [MACEDONIA_BOUNDS.minLat, MACEDONIA_BOUNDS.minLng],
          [MACEDONIA_BOUNDS.maxLat, MACEDONIA_BOUNDS.maxLng],
        ]}
        maxBoundsViscosity={0.85}
        attributionControl={false}
      >
        <TileLayer url={CARTODB_POSITRON} attribution="" />
        <MapZoomControls />
        <MapEventHandler onMoveEnd={handleMoveEnd} />
        <FitBoundsEffect trigger={fitBoundsTrigger} />
        <MapClickHandler onClick={handleMapClick} />

        <SitesClusterLayer
          sites={sites}
          selectedSiteId={selectedSiteId}
          setSelectedSiteId={setSelectedSiteId}
        />
      </MapContainer>

      <MapAttributionStrip />

      {isLoading && (
        <div className={styles.overlay} role="status" aria-live="polite" aria-busy="true">
          <div className={styles.overlayContent}>
            <Spinner aria-label="Loading map data" />
            <span className={styles.overlayMessage}>Loading sites…</span>
          </div>
        </div>
      )}

      {!isLoading && isFetching && (
        <div className={styles.refreshingBanner} role="status" aria-live="polite" aria-atomic="true">
          <span className={styles.refreshingSpinnerWrap} aria-hidden>
            <Spinner size="sm" />
          </span>
          <span className={styles.refreshingLabel}>Refreshing map…</span>
        </div>
      )}

      {isError && (
        <div className={styles.overlay}>
          <div className={styles.overlayContent}>
            <span className={styles.overlayMessage}>Unable to load map data</span>
            <button
              type="button"
              onClick={() => refetch()}
              className={styles.toolbarBtn}
            >
              Retry
            </button>
          </div>
        </div>
      )}

      {!isLoading && !isFetching && !isError && sites.length === 0 && (
        <div className={styles.overlay}>
          <div className={styles.overlayContent}>
            <span className={styles.overlayMessage}>
              {statusFilter ? 'No sites match the selected filters' : 'No sites in this area'}
            </span>
            {statusFilter && (
              <button
                type="button"
                className={styles.toolbarBtn}
                onClick={() => {
                  setStatusFilter('');
                  router.replace('/dashboard/map', { scroll: false });
                }}
              >
                Reset filters
              </button>
            )}
          </div>
        </div>
      )}

      <AnimatePresence>
        {selectedSite ? (
          <SitePreviewPanel
            key={selectedSite.id}
            site={selectedSite}
            onClose={() => setSelectedSiteId(null)}
          />
        ) : null}
      </AnimatePresence>

    </div>
  );
}
