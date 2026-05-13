import { Injectable, NotFoundException } from '@nestjs/common';
import { loadFeatureFlags } from '../../config/feature-flags';
import { MapMvtTilesFallbackService } from './map-mvt-tiles-fallback.service';
import { MapMvtTilesPostgisService } from './map-mvt-tiles-postgis.service';
import type { MvtTileResult } from './map-mvt-tiles.types';

export type { MvtTileResult } from './map-mvt-tiles.types';

@Injectable()
export class MapMvtTilesService {
  constructor(
    private readonly postgis: MapMvtTilesPostgisService,
    private readonly fallback: MapMvtTilesFallbackService,
  ) {}

  async getTileOrThrow(z: number, x: number, y: number): Promise<MvtTileResult> {
    const flags = loadFeatureFlags();
    if (!flags.mapTileFormatVector) {
      throw new NotFoundException({
        code: 'MAP_MVT_DISABLED',
        message: 'Vector tiles are disabled. Set MAP_TILE_FORMAT_VECTOR=true after CDN wiring.',
        details: { z, x, y },
      });
    }

    if (flags.mapPostgisEnabled) {
      return this.postgis.generateTile(z, x, y);
    }
    return this.fallback.generateTile(z, x, y);
  }
}
