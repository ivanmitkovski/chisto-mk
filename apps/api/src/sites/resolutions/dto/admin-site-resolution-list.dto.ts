import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SiteResolutionStatus } from '../../../prisma-client';
import { PaginationQueryDto20 } from '../../../common/dto/pagination-query.dto';
import { IsEnum, IsOptional, IsString, Length, Matches } from 'class-validator';

export class AdminSiteResolutionListItemDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  siteId!: string;

  @ApiPropertyOptional({ nullable: true })
  siteAddress!: string | null;

  @ApiProperty({ enum: SiteResolutionStatus })
  status!: SiteResolutionStatus;

  @ApiProperty({ type: [String] })
  mediaUrls!: string[];

  @ApiPropertyOptional({ nullable: true })
  note!: string | null;

  @ApiProperty()
  isReporterSubmission!: boolean;

  @ApiProperty()
  createdAt!: string;

  @ApiPropertyOptional({ nullable: true })
  submitterDisplayLabel!: string | null;

  @ApiProperty()
  siteStatus!: string;
}

export class AdminSiteResolutionListMetaDto {
  @ApiProperty()
  page!: number;

  @ApiProperty()
  limit!: number;

  @ApiProperty()
  total!: number;
}

export class AdminSiteResolutionListResponseDto {
  @ApiProperty({ type: [AdminSiteResolutionListItemDto] })
  data!: AdminSiteResolutionListItemDto[];

  @ApiProperty({ type: AdminSiteResolutionListMetaDto })
  meta!: AdminSiteResolutionListMetaDto;
}

export class ListAdminSiteResolutionsQueryDto extends PaginationQueryDto20 {
  @ApiPropertyOptional({ enum: SiteResolutionStatus })
  @IsOptional()
  @IsEnum(SiteResolutionStatus)
  status?: SiteResolutionStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(20, 40)
  @Matches(/^[A-Za-z0-9_-]+$/)
  siteId?: string;
}
