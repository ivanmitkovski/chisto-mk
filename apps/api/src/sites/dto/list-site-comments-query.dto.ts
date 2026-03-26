import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, Max, MaxLength, Min, MinLength } from 'class-validator';

export enum SiteCommentsSort {
  TOP = 'top',
  NEW = 'new',
}

export class ListSiteCommentsQueryDto {
  @ApiPropertyOptional({ default: 1, minimum: 1 })
  @Type(() => Number)
  @IsOptional()
  @IsInt()
  @Min(1)
  page = 1;

  @ApiPropertyOptional({ default: 20, minimum: 1, maximum: 100 })
  @Type(() => Number)
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(50)
  limit = 20;

  @ApiPropertyOptional({
    description:
      'Optional parent comment id. When omitted, returns root comments with nested replies.',
  })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(64)
  parentId?: string;

  @ApiPropertyOptional({
    enum: SiteCommentsSort,
    default: SiteCommentsSort.TOP,
    description: 'Sort comments by relevance/top or recency/new',
  })
  @IsOptional()
  @IsEnum(SiteCommentsSort)
  sort: SiteCommentsSort = SiteCommentsSort.TOP;
}
