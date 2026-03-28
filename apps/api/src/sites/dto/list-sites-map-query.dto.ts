import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SiteStatus } from '../../prisma-client';
import { Type } from 'class-transformer';
import { IsEnum, IsIn, IsInt, IsNumber, IsOptional, Max, Min } from 'class-validator';

export class ListSitesMapQueryDto {
  @ApiProperty({
    description: 'Center latitude for map view',
    example: 41.6086,
  })
  @IsNumber()
  @Type(() => Number)
  lat!: number;

  @ApiProperty({
    description: 'Center longitude for map view',
    example: 21.7453,
  })
  @IsNumber()
  @Type(() => Number)
  lng!: number;

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
}
