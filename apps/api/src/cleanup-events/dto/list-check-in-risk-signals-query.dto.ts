import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MinLength } from 'class-validator';
import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';

export const CHECK_IN_RISK_SIGNAL_STATUSES = ['active', 'resolved', 'all'] as const;

/** Pagination + optional status filter (defaults: page 1, limit 50, status active). */
export class ListCheckInRiskSignalsQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({
    enum: CHECK_IN_RISK_SIGNAL_STATUSES,
    default: 'active',
    description: 'active = unresolved and not expired; resolved = handled; all = no status filter',
  })
  @IsOptional()
  @IsIn([...CHECK_IN_RISK_SIGNAL_STATUSES])
  status?: (typeof CHECK_IN_RISK_SIGNAL_STATUSES)[number];

  @ApiPropertyOptional({ description: 'Filter signals for a specific cleanup event' })
  @IsOptional()
  @IsString()
  @MinLength(1)
  eventId?: string;
}
