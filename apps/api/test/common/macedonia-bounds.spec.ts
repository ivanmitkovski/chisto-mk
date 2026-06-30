/// <reference types="jest" />

import { isWithinMacedonia, MACEDONIA_BOUNDS } from '../../src/common/geo/macedonia-bounds';

describe('isWithinMacedonia', () => {
  it('accepts Skopje city center', () => {
    expect(isWithinMacedonia(41.9981, 21.4254)).toBe(true);
  });

  it('rejects coordinates outside the country', () => {
    expect(isWithinMacedonia(48.8566, 2.3522)).toBe(false); // Paris
    expect(isWithinMacedonia(0, 0)).toBe(false);
  });

  it('treats the bounding box edges as inclusive', () => {
    expect(isWithinMacedonia(MACEDONIA_BOUNDS.minLat, MACEDONIA_BOUNDS.minLng)).toBe(true);
    expect(isWithinMacedonia(MACEDONIA_BOUNDS.maxLat, MACEDONIA_BOUNDS.maxLng)).toBe(true);
  });

  it('rejects non-finite values', () => {
    expect(isWithinMacedonia(Number.NaN, 21)).toBe(false);
    expect(isWithinMacedonia(41, Number.POSITIVE_INFINITY)).toBe(false);
  });
});
