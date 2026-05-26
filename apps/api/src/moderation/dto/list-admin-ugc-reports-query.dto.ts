import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { Type } from 'class-transformer';

export const UGC_REPORT_STATUSES = ['OPEN', 'REVIEWED', 'DISMISSED', 'ESCALATED', 'HIDDEN'] as const;
export const UGC_SUBJECT_TYPES = [
  'site_comment',
  'event_chat_message',
  'user',
  'site',
  'event',
  'safety_issue',
] as const;

export class ListAdminUgcReportsQueryDto {
  @ApiPropertyOptional({ default: 1, minimum: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ default: 50, minimum: 1, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;

  @ApiPropertyOptional({ enum: UGC_REPORT_STATUSES })
  @IsOptional()
  @IsIn([...UGC_REPORT_STATUSES])
  status?: (typeof UGC_REPORT_STATUSES)[number];

  @ApiPropertyOptional({ enum: UGC_SUBJECT_TYPES })
  @IsOptional()
  @IsIn([...UGC_SUBJECT_TYPES])
  subjectType?: (typeof UGC_SUBJECT_TYPES)[number];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  reporterId?: string;
}
