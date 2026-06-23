'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { AnimatePresence } from 'framer-motion';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { MapContainer, TileLayer, useMap, useMapEvents } from 'react-leaflet';
import MarkerClusterGroup from 'react-leaflet-cluster';
import L from 'leaflet';
import '@/features/map/leaflet-setup';
import 'react-leaflet-cluster/dist/assets/MarkerCluster.css';
import 'react-leaflet-cluster/dist/assets/MarkerCluster.Default.css';
import { Spinner } from '@/components/ui';
import { MapAttributionStrip } from './map-attribution-strip';
import { MapHeatmapLayer } from './map-heatmap-layer';
import { MapMarker } from './map-marker';
import { MapToolbar } from './map-toolbar';
import { MapZoomControls } from './map-zoom-controls';
import { SitePreviewPanel } from './site-preview-panel';
import type { SiteMapRow } from '../data/map-adapter';
import { registerMapAdapterBroadcastSync } from '../data/map-adapter';
import { useSitesMap } from '../hooks/use-sites-map';
import { MACEDONIA_BOUNDS, SERVER_CLUSTER_MAX_ZOOM } from '../map-constants';
import { useTileUrl } from '../hooks/use-tile-url';
import { createCountClusterIcon } from '../utils/map-count-cluster-icon';
import { CLUSTER_EXPAND_MIN_ZOOM, flyToClusterContents } from '../utils/map-cluster-navigation';
import styles from './sites-map.module.css';

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
  return createCountClusterIcon(cluster.getChildCount());
}

type SitesClusterLayerProps = {
  sites: SiteMapRow[];
  selectedSiteId: string | null;
  setSelectedSiteId: (id: string | null) => void;
  zoom: number;
};

function SitesClusterLayer({ sites, selectedSiteId, setSelectedSiteId, zoom }: SitesClusterLayerProps) {
  const map = useMap();
  const serverClusterMode =
    zoom <= SERVER_CLUSTER_MAX_ZOOM && sites.length > 0 && sites.every((s) => s.isCluster === true);

  const onClusterClick = useCallback(
    (e: L.LeafletMouseEvent) => {
      flyToClusterContents(map, e.layer);
    },
    [map],
  );

  const markers = sites.map((site) => (
    <MapMarker
      key={site.id}
      site={site}
      selected={selectedSiteId === site.id}
      onClick={() => setSelectedSiteId(site.id === selectedSiteId ? null : site.id)}
    />
  ));

  if (serverClusterMode) {
    return <>{markers}</>;
  }

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
      {markers}
    </MarkerClusterGroup>
  );
}

export function SitesMap() {
  const t = useTranslations('map');
  const tCommon = useTranslations('common');
  const router = useRouter();
  const tileUrl = useTileUrl();
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [fitBoundsTrigger, setFitBoundsTrigger] = useState(0);

  const {
    statusFilter,
    includeArchived,
    selectedSiteId,
    selectedSite,
    sites,
    isLoading,
    isFetching,
    isError,
    refetch,
    center,
    setCenter,
    setZoom,
    updateView,
    setStatusFilter,
    setSelectedSiteId,
    zoom,
    showHeatmap,
    toggleHeatmap,
    heatmapPoints,
    heatmapFetching,
    searchDraft,
    setSearchDraft,
    searchMessage,
    runSearch,
    resultCapped,
  } = useSitesMap();

  useEffect(() => {
    const dispose = registerMapAdapterBroadcastSync();
    return dispose;
  }, []);

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
        includeArchived={includeArchived}
        onIncludeArchivedChange={(value) => {
          const next = new URLSearchParams(window.location.search);
          if (value) next.set('includeArchived', 'true');
          else next.delete('includeArchived');
          router.replace(next.toString() ? `/dashboard/map?${next.toString()}` : '/dashboard/map', {
            scroll: false,
          });
        }}
        showHeatmap={showHeatmap}
        onHeatmapChange={toggleHeatmap}
        searchDraft={searchDraft}
        onSearchDraftChange={setSearchDraft}
        onSearch={() => void runSearch()}
        searchMessage={searchMessage}
        resultCapped={resultCapped}
      />

      <MapContainer
        center={[...center]}
        zoom={zoom}
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
        <TileLayer url={tileUrl} attribution="" />
        <MapZoomControls />
        <MapEventHandler onMoveEnd={handleMoveEnd} />
        <FitBoundsEffect trigger={fitBoundsTrigger} />
        <MapClickHandler onClick={handleMapClick} />

        {showHeatmap && heatmapPoints.length > 0 ? (
          <MapHeatmapLayer points={heatmapPoints} zoom={zoom} />
        ) : null}

        <SitesClusterLayer
          sites={sites}
          selectedSiteId={selectedSiteId}
          setSelectedSiteId={setSelectedSiteId}
          zoom={zoom}
        />
      </MapContainer>

      <MapAttributionStrip />

      {isLoading && (
        <div className={styles.overlay} role="status" aria-live="polite" aria-busy="true">
          <div className={styles.overlayContent}>
            <Spinner aria-label={t('loadingMapData')} />
            <span className={styles.overlayMessage}>{t('loadingSites')}</span>
          </div>
        </div>
      )}

      {!isLoading && isFetching && (
        <div className={styles.refreshingBanner} role="status" aria-live="polite" aria-atomic="true">
          <span className={styles.refreshingSpinnerWrap} aria-hidden>
            <Spinner size="sm" />
          </span>
          <span className={styles.refreshingLabel}>{t('refreshingMap')}</span>
        </div>
      )}

      {!isLoading && showHeatmap && heatmapFetching ? (
        <div className={styles.heatmapBanner} role="status" aria-live="polite">
          {t('updatingHeatmap')}
        </div>
      ) : null}

      {isError && (
        <div className={styles.overlay}>
          <div className={styles.overlayContent}>
            <span className={styles.overlayMessage}>{t('loadFailed')}</span>
            <button
              type="button"
              onClick={() => refetch()}
              className={styles.toolbarBtn}
            >
              {tCommon('retry')}
            </button>
          </div>
        </div>
      )}

      {!isLoading && !isFetching && !isError && sites.length === 0 && (
        <div className={styles.overlay}>
          <div className={styles.overlayContent}>
            <span className={styles.overlayMessage}>
              {statusFilter ? t('noSitesFiltered') : t('noSitesInArea')}
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
                {t('resetFilters')}
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
