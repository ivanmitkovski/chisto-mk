'use client';

import { useEffect, useMemo } from 'react';
import { useTranslations } from 'next-intl';
import { MapContainer, Marker, Popup, TileLayer, useMap } from 'react-leaflet';
import L from 'leaflet';
import '@/features/map/leaflet-setup';
import { Card, SectionState } from '@/components/ui';
import { MapAttributionStrip } from '@/features/map/components/map-attribution-strip';
import { MapZoomControls } from '@/features/map/components/map-zoom-controls';
import { useTileUrl } from '@/features/map/hooks/use-tile-url';
import { INITIAL_ZOOM, MACEDONIA_BOUNDS, MACEDONIA_CENTER } from '@/features/map/map-constants';
import { createCountClusterIcon } from '@/features/map/utils/map-count-cluster-icon';
import type { GeoCluster } from '../data/active-users.types';
import mapStyles from '@/features/map/components/sites-map.module.css';
import styles from './active-users-geo-map.module.css';

const CITY_COORDS: Record<string, [number, number]> = {
  Skopje: [41.9981, 21.4254],
  Bitola: [41.0319, 21.3347],
  Kumanovo: [42.1322, 21.7144],
  Prilep: [41.3458, 21.555],
  Tetovo: [42.0106, 20.9714],
  Ohrid: [41.1172, 20.8019],
  Veles: [41.7156, 21.7756],
  Štip: [41.7458, 22.1958],
  Strumica: [41.4375, 22.6428],
};

function clusterPosition(cluster: GeoCluster, index: number): [number, number] {
  if (cluster.city && CITY_COORDS[cluster.city]) {
    return CITY_COORDS[cluster.city];
  }
  const baseLat = 41.6;
  const baseLng = 21.7;
  return [baseLat + (index % 5) * 0.08, baseLng + Math.floor(index / 5) * 0.12];
}

function FitMacedoniaBounds() {
  const map = useMap();
  useEffect(() => {
    const bounds = L.latLngBounds(
      [MACEDONIA_BOUNDS.minLat, MACEDONIA_BOUNDS.minLng],
      [MACEDONIA_BOUNDS.maxLat, MACEDONIA_BOUNDS.maxLng],
    );
    map.fitBounds(bounds, { padding: [12, 12], maxZoom: 7 });
  }, [map]);
  return null;
}

type ActiveUsersGeoMapProps = {
  clusters: GeoCluster[];
  loadError?: string;
};

export function ActiveUsersGeoMap({ clusters, loadError }: ActiveUsersGeoMapProps) {
  const t = useTranslations('activeUsers');
  const tileUrl = useTileUrl();
  const totalUsers = useMemo(
    () => clusters.reduce((sum, cluster) => sum + cluster.count, 0),
    [clusters],
  );
  const markers = useMemo(
    () =>
      clusters.map((cluster, index) => ({
        cluster,
        position: clusterPosition(cluster, index),
      })),
    [clusters],
  );

  function formatLocation(cluster: GeoCluster): string {
    const parts = [cluster.city, cluster.country].filter(Boolean);
    return parts.length > 0 ? parts.join(', ') : t('geo.unknownCity');
  }

  return (
    <Card padding="md" className={styles.panel}>
      <div className={styles.header}>
        <h3 className={styles.title}>{t('geo.title')}</h3>
        <p className={styles.subtitle}>{t('geo.userCount', { count: totalUsers })}</p>
      </div>

      {loadError ? (
        <SectionState variant="error" message={loadError} />
      ) : (
        <div
          className={`${mapStyles.mapWrap} ${styles.embed}`}
          role="img"
          aria-label={t('geo.mapDescription')}
        >
          <MapContainer
            center={[...MACEDONIA_CENTER]}
            zoom={INITIAL_ZOOM}
            className={mapStyles.map}
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
            <FitMacedoniaBounds />
            <MapZoomControls />
            {markers.map(({ cluster, position }, idx) => (
              <Marker
                key={`${cluster.city}-${cluster.country}-${idx}`}
                position={position}
                icon={createCountClusterIcon(cluster.count)}
              >
                <Popup>
                  {formatLocation(cluster)} — {cluster.count}
                </Popup>
              </Marker>
            ))}
          </MapContainer>
          <MapAttributionStrip />
        </div>
      )}
    </Card>
  );
}
