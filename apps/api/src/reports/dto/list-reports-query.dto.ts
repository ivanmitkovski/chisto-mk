import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { PaginationQueryDto20 } from '../../common/dto/pagination-query.dto';
import { ReportStatus } from '../../prisma-client';
import { IsBoolean, IsEnum, IsIn, IsOptional, IsString, Length, Matches } from 'class-validator';
import { StrictBoolean } from '../../common/transformers/strict-boolean.transformer';
import {
  ADMIN_REPORT_SORT_FIELDS,
  type AdminReportSortField,
} from './admin-report-sort-query.dto';

function trimOptionalSearch(value: unknown): string | undefined {
  if (value == null || value === '') {
    return undefined;
  }
  if (typeof value === 'string') {
    const trimmed = value.trim();
    return trimmed.length === 0 ? undefined : trimmed;
  }
  return value as string;
}

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
  @StrictBoolean()
  @IsOptional()
  @IsBoolean()
  duplicatesOnly?: boolean;

  @ApiPropertyOptional({ description: 'Case-insensitive search on name, location, or report number' })
  @IsOptional()
  @Transform(({ value }) => trimOptionalSearch(value))
  @IsString()
  search?: string;

  @ApiPropertyOptional({
    description: 'Alias for search (case-insensitive name, location, or report number)',
  })
  @IsOptional()
  @Transform(({ value }) => trimOptionalSearch(value))
  @IsString()
  q?: string;

  @ApiPropertyOptional({ enum: ADMIN_REPORT_SORT_FIELDS, default: 'dateReportedAt' })
  @IsOptional()
  @IsIn([...ADMIN_REPORT_SORT_FIELDS])
  sort?: AdminReportSortField;

  @ApiPropertyOptional({ enum: ['asc', 'desc'], default: 'desc' })
  @IsOptional()
  @IsIn(['asc', 'desc'])
  dir?: 'asc' | 'desc';
}
