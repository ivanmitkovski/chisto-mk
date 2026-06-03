export function tile2lon(x: number, z: number): number {
  return (x / Math.pow(2, z)) * 360 - 180;
}

export function tile2lat(y: number, z: number): number {
  const n = Math.PI - (2 * Math.PI * y) / Math.pow(2, z);
  return (180 / Math.PI) * Math.atan(0.5 * (Math.exp(n) - Math.exp(-n)));
}

export const MVT_MAX_ZOOM = 16;

/** Validates WebMercator tile coordinates; throws if invalid. */
export function assertValidMvtTileCoords(z: number, x: number, y: number): void {
  if (!Number.isInteger(z) || z < 0 || z > MVT_MAX_ZOOM) {
    throw new Error(`Invalid MVT zoom: ${z}`);
  }
  const maxIndex = Math.pow(2, z);
  if (!Number.isInteger(x) || x < 0 || x >= maxIndex) {
    throw new Error(`Invalid MVT x: ${x} for z=${z}`);
  }
  if (!Number.isInteger(y) || y < 0 || y >= maxIndex) {
    throw new Error(`Invalid MVT y: ${y} for z=${z}`);
  }
}
