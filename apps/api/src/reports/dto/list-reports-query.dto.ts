import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaginationQueryDto20 } from '../../common/dto/pagination-query.dto';
import { ReportStatus } from '../../prisma-client';
import { Type } from 'class-transformer';
import { IsBoolean, IsEnum, IsOptional, IsString, Length, Matches } from 'class-validator';

export class ListReportsQueryDto extends PaginationQueryDto20 {
  @ApiPropertyOptional({ enum: ReportStatus })
  @IsOptional()
  @IsEnum(ReportStatus)
  status?: ReportStatus;

  @ApiPropertyOptional({
    description: 'Optional filter by site id',
    example: 'cm1234567890abcdefghijkl',
  })
  @IsOptional()
  @IsString()
  @Length(20, 40)
  @Matches(/^[A-Za-z0-9_-]+$/, {
    message: 'siteId must be an alphanumeric id (e.g. CUID)',
  })
  siteId?: string;

  @ApiPropertyOptional({
    description: 'When true, returns only reports that are in a duplicate relationship',
    default: false,
  })
  @Type(() => Boolean)
  @IsOptional()
  @IsBoolean()
  duplicatesOnly?: boolean;

}
