import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { PaginationQueryDto20Max50 } from '../../common/dto/pagination-query.dto';

export enum SiteCommentsSort {
  TOP = 'top',
  NEW = 'new',
}

export class ListSiteCommentsQueryDto extends PaginationQueryDto20Max50 {
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
