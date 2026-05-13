import { ApiPropertyOptional } from '@nestjs/swagger';
import { SiteStatus } from '../../prisma-client';
import { Type } from 'class-transformer';
import { IsBoolean, IsEnum, IsIn, IsInt, IsNumber, IsOptional, Max, Min } from 'class-validator';

import { GeoPointLatLngDto } from '../../common/dto/geo-point.dto';

export class ListSitesMapQueryDto extends GeoPointLatLngDto {
  @ApiPropertyOptional({
    description: 'Map zoom level (used for server-side query safety limits and future clustering)',
    minimum: 1,
    maximum: 22,
    example: 13,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(1)
  @Max(22)
  zoom?: number;

  @ApiPropertyOptional({
    description: 'Search radius in km',
    default: 80,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(0.1)
  @Max(500)
  radiusKm = 80;

  @ApiPropertyOptional({ enum: SiteStatus })
  @IsOptional()
  @IsEnum(SiteStatus)
  status?: SiteStatus;

  @ApiPropertyOptional({ default: 200, minimum: 10, maximum: 500 })
  @Type(() => Number)
  @IsOptional()
  @IsInt()
  @Min(10)
  @Max(500)
  limit = 200;

  @ApiPropertyOptional({
    enum: ['full', 'lite'],
    description:
      'lite: smaller map JSON (one thumbnail URL, no engagement fields). full: default shape.',
    default: 'full',
  })
  @IsOptional()
  @IsIn(['full', 'lite'])
  detail: 'full' | 'lite' = 'full';

  @ApiPropertyOptional({
    description: 'Optional visible bounds south edge for viewport-based map fetches',
    example: 41.55,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(-90)
  @Max(90)
  minLat?: number;

  @ApiPropertyOptional({
    description: 'Optional visible bounds north edge for viewport-based map fetches',
    example: 41.68,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(-90)
  @Max(90)
  maxLat?: number;

  @ApiPropertyOptional({
    description: 'Optional visible bounds west edge for viewport-based map fetches',
    example: 21.62,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(-180)
  @Max(180)
  minLng?: number;

  @ApiPropertyOptional({
    description: 'Optional visible bounds east edge for viewport-based map fetches',
    example: 21.88,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(-180)
  @Max(180)
  maxLng?: number;

  @ApiPropertyOptional({
    description: 'Include archived/cold cleaned sites in map results',
    default: false,
  })
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  includeArchived = false;

  @ApiPropertyOptional({
    description:
      'Low-priority speculative fetch (e.g. pan extrapolation). Same response shape; included in cache keys.',
    default: false,
  })
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  prefetch = false;
}

