import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaginationQueryDto20 } from '../../common/dto/pagination-query.dto';
import { SiteStatus } from '../../prisma-client';
import { Type } from 'class-transformer';
import { IsBoolean, IsEnum, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export enum SiteFeedSort {
  HYBRID = 'hybrid',
  RECENT = 'recent',
}

export enum SiteFeedMode {
  FOR_YOU = 'for_you',
  LATEST = 'latest',
}

export class ListSitesQueryDto extends PaginationQueryDto20 {
  @ApiPropertyOptional({
    description: 'Center latitude for geo search (with lng and radiusKm)',
    example: 41.6086,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  lat?: number;

  @ApiPropertyOptional({
    description: 'Center longitude for geo search (with lat and radiusKm)',
    example: 21.7453,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  lng?: number;

  @ApiPropertyOptional({
    description: 'Search radius in km (default 10 when lat/lng provided)',
    default: 10,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(0.1)
  @Max(500)
  radiusKm = 10;

  @ApiPropertyOptional({ enum: SiteStatus })
  @IsOptional()
  @IsEnum(SiteStatus)
  status?: SiteStatus;

  @ApiPropertyOptional({
    enum: SiteFeedSort,
    default: SiteFeedSort.HYBRID,
    description: 'Feed sort mode',
  })
  @IsOptional()
  @IsEnum(SiteFeedSort)
  sort: SiteFeedSort = SiteFeedSort.HYBRID;

  @ApiPropertyOptional({
    enum: SiteFeedMode,
    default: SiteFeedMode.FOR_YOU,
    description: 'Feed mode for personalized vs latest ranking.',
  })
  @IsOptional()
  @IsEnum(SiteFeedMode)
  mode: SiteFeedMode = SiteFeedMode.FOR_YOU;

  @ApiPropertyOptional({
    description: 'Include ranking explainability metadata in each feed item.',
    default: false,
  })
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  explain = false;

  @ApiPropertyOptional({
    description:
      'Cursor token for feed pagination. When set, server ignores page offset and returns next window.',
    example: '1711470000000|site_123',
  })
  @IsOptional()
  @IsString()
  cursor?: string;
}
