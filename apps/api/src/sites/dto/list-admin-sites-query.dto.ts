import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString } from 'class-validator';
import { SiteStatus } from '../../prisma-client';
import { PaginationQueryDto20 } from '../../common/dto/pagination-query.dto';

export class ListAdminSitesQueryDto extends PaginationQueryDto20 {
  @ApiPropertyOptional({ enum: SiteStatus })
  @IsOptional()
  @IsEnum(SiteStatus)
  status?: SiteStatus;

  @ApiPropertyOptional({ description: 'Search by site id or description' })
  @IsOptional()
  @IsString()
  search?: string;
}
