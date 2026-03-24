import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SiteStatus } from '../../prisma-client';
import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsNumber, IsOptional, Max, Min } from 'class-validator';

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
}
