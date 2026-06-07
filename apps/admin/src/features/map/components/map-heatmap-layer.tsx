'use client';

import { Circle } from 'react-leaflet';
import type { MapHeatPoint } from '@chisto/map-contracts';

const MAX_INTENSITY = 20;

function heatRadius(intensity: number, zoom: number): number {
  const base = 120 + intensity * 8;
  return Math.max(40, base / Math.max(1, zoom - 6));
}

function heatOpacity(intensity: number): number {
  return Math.min(0.55, 0.15 + intensity / MAX_INTENSITY);
}

type MapHeatmapLayerProps = {
  points: MapHeatPoint[];
  zoom: number;
};

export function MapHeatmapLayer({ points, zoom }: MapHeatmapLayerProps) {
  return (
    <>
      {points.map((point) => (
        <Circle
          key={`${point.latitude}:${point.longitude}:${point.weight}`}
          center={[point.latitude, point.longitude]}
          radius={heatRadius(point.weight, zoom)}
          pathOptions={{
            color: 'transparent',
            fillColor: '#c2410c',
            fillOpacity: heatOpacity(point.weight),
            weight: 0,
          }}
        />
      ))}
    </>
  );
}
