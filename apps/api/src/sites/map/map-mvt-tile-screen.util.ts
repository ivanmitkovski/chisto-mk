import { createHash } from 'crypto';

export function lonToTileX(lon: number, minLon: number, maxLon: number): number {
  const extent = 4096;
  return Math.round(((lon - minLon) / (maxLon - minLon)) * extent);
}

export function latToTileY(lat: number, minLat: number, maxLat: number): number {
  const extent = 4096;
  return Math.round(((maxLat - lat) / (maxLat - minLat)) * extent);
}

export function computeMvtTileEtag(
  z: number,
  x: number,
  y: number,
  maxUpdated: Date | null,
  count: number,
): string {
  const payload = `${z}:${x}:${y}:${maxUpdated?.toISOString() ?? 'none'}:${count}`;
  return `"${createHash('md5').update(payload).digest('hex')}"`;
}
