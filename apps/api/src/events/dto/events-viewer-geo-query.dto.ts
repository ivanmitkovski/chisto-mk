import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsNumber, IsOptional, Max, Min } from 'class-validator';

/** Optional viewer coordinates for distance-to-site (list + detail). Both must be sent together. */
export class EventsViewerGeoQueryDto {
  @ApiPropertyOptional({
    description: 'Viewer latitude (WGS84); with nearLng fills siteDistanceKm on each event',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  nearLat?: number;

  @ApiPropertyOptional({
    description: 'Viewer longitude (WGS84); with nearLat fills siteDistanceKm on each event',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  nearLng?: number;

  /** True when both optional geo params are present (caller validated pair completeness). */
  hasViewerGeo(): boolean {
    return this.nearLat != null && this.nearLng != null;
  }
}
