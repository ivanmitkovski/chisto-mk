import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional } from 'class-validator';

export const ADMIN_REPORT_SORT_FIELDS = [
  'dateReportedAt',
  'reportNumber',
  'name',
  'status',
] as const;

export type AdminReportSortField = (typeof ADMIN_REPORT_SORT_FIELDS)[number];

export class AdminReportSortQueryDto {
  @ApiPropertyOptional({
    enum: ADMIN_REPORT_SORT_FIELDS,
    default: 'dateReportedAt',
  })
  @IsOptional()
  @IsIn([...ADMIN_REPORT_SORT_FIELDS])
  sort?: AdminReportSortField;

  @ApiPropertyOptional({ enum: ['asc', 'desc'], default: 'desc' })
  @IsOptional()
  @IsIn(['asc', 'desc'])
  dir?: 'asc' | 'desc';
}
