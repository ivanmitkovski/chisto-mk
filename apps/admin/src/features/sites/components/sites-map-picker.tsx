'use client';

import { useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { MapContainer, Marker, TileLayer, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import '@/features/map/leaflet-setup';
import { MACEDONIA_CENTER } from '@/features/map/map-constants';
import styles from './sites-map-picker.module.css';

const CARTODB_POSITRON =
  'https://{s}.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}{r}.png';

const defaultIcon = L.icon({
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});

type SitesMapPickerProps = {
  latitude: number | null;
  longitude: number | null;
  onPick: (lat: number, lng: number) => void;
};

function MapClickHandler({ onPick }: { onPick: (lat: number, lng: number) => void }) {
  useMapEvents({
    click: (event) => {
      onPick(event.latlng.lat, event.latlng.lng);
    },
  });
  return null;
}

export function SitesMapPicker({ latitude, longitude, onPick }: SitesMapPickerProps) {
  const t = useTranslations('sites');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return <div className={styles.placeholder} aria-hidden />;
  }

  const center: [number, number] =
    latitude != null && longitude != null
      ? [latitude, longitude]
      : [MACEDONIA_CENTER[0], MACEDONIA_CENTER[1]];

  return (
    <div className={styles.wrap}>
      <p className={styles.hint}>{t('mapPicker.hint')}</p>
      <MapContainer center={center} zoom={10} className={styles.map} scrollWheelZoom>
        <TileLayer attribution='&copy; <a href="https://carto.com/">CARTO</a>' url={CARTODB_POSITRON} />
        <MapClickHandler onPick={onPick} />
        {latitude != null && longitude != null ? (
          <Marker position={[latitude, longitude]} icon={defaultIcon} />
        ) : null}
      </MapContainer>
    </div>
  );
}
