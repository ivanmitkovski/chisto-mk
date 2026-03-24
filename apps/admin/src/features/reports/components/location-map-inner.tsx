'use client';

import { useCallback, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Icon } from '@/components/ui';
import type { ReportMapPin } from '../types';
import styles from './location-map-card.module.css';

const CARTODB_POSITRON =
  'https://{s}.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}{r}.png';
const CARTODB_ATTRIBUTION =
  '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>';

function createMarkerIcon() {
  return L.divIcon({
    className: styles.markerIcon,
    html: `<span class="${styles.markerPin}"></span>`,
    iconSize: [32, 32],
    iconAnchor: [16, 16],
    popupAnchor: [0, -16],
  });
}

function RecenterControl({
  center,
  onRecenter,
}: {
  center: [number, number];
  onRecenter: () => void;
}) {
  const map = useMap();

  return (
    <button
      type="button"
      className={styles.recenterBtn}
      onClick={() => {
        map.flyTo(center, 15, { duration: 0.5 });
        onRecenter();
      }}
      aria-label="Recenter map on report location"
      title="Recenter map"
    >
      <Icon name="location" size={18} />
    </button>
  );
}

type LocationMapInnerProps = {
  mapPin: ReportMapPin;
  locationLabel: string;
};

export function LocationMapInner({ mapPin, locationLabel }: LocationMapInnerProps) {
  const [, setRecenterKey] = useState(0);
  const center: [number, number] = [mapPin.latitude, mapPin.longitude];

  const handleRecenter = useCallback(() => {
    setRecenterKey((k) => k + 1);
  }, []);

  return (
    <div className={styles.mapWrap}>
      <MapContainer
        center={center}
        zoom={15}
        className={styles.map}
        zoomControl={true}
        attributionControl={false}
        style={{ height: '100%', minHeight: '16rem' }}
      >
        <TileLayer url={CARTODB_POSITRON} attribution={CARTODB_ATTRIBUTION} />
        <Marker position={center} icon={createMarkerIcon()}>
          <Popup>{locationLabel}</Popup>
        </Marker>
        <RecenterControl center={center} onRecenter={handleRecenter} />
      </MapContainer>
      <div className={styles.attribution} aria-hidden>
        © OpenStreetMap · © CARTO
      </div>
    </div>
  );
}
