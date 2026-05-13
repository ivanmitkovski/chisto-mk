import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsLatitude, IsLongitude, IsOptional, IsString, MaxLength } from 'class-validator';

/**
 * Optional viewer coordinates for distance-to-site (events list/detail, etc.).
 * Callers must reject requests where exactly one of the pair is set.
 */
export class ViewerGeoNearOptionalDto {
  @ApiPropertyOptional({
    description: 'Viewer latitude (WGS84); with nearLng fills siteDistanceKm on each item',
    example: 41.9973,
  })
  @IsOptional()
  @Type(() => Number)
  @IsLatitude()
  nearLat?: number;

  @ApiPropertyOptional({
    description: 'Viewer longitude (WGS84); with nearLat fills siteDistanceKm on each item',
    example: 21.4254,
  })
  @IsOptional()
  @Type(() => Number)
  @IsLongitude()
  nearLng?: number;

  hasViewerGeo(): boolean {
    return this.nearLat != null && this.nearLng != null;
  }
}

/** Map-style center (`lat` / `lng`) with numeric coercion for query DTOs. */
export class GeoPointLatLngDto {
  @ApiProperty({
    description: 'Center latitude for map-style queries (or chat location pins)',
    example: 41.6086,
  })
  @IsLatitude()
  @Type(() => Number)
  lat!: number;

  @ApiProperty({
    description: 'Center longitude for map-style queries (or chat location pins)',
    example: 21.7453,
  })
  @IsLongitude()
  @Type(() => Number)
  lng!: number;
}

/** Site/report payloads using `latitude` / `longitude` (no `Type()` — JSON body numbers). */
export class GeoPointLatitudeLongitudeDto {
  @ApiProperty({ description: 'Latitude', example: 41.9981 })
  @IsLatitude()
  latitude!: number;

  @ApiProperty({ description: 'Longitude', example: 21.4254 })
  @IsLongitude()
  longitude!: number;
}

/** Optional map pin with human-readable label (event chat location messages). */
export class GeoPointLatLngWithLabelDto extends GeoPointLatLngDto {
  @ApiPropertyOptional({ example: 'City Park North' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  label?: string;
}
