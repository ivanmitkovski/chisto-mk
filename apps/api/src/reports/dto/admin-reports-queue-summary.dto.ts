import { ApiProperty } from '@nestjs/swagger';

export class AdminReportsQueueSummaryDto {
  @ApiProperty()
  total!: number;

  @ApiProperty()
  needAttentionCount!: number;

  @ApiProperty()
  duplicatesCount!: number;

  @ApiProperty({ type: 'object', additionalProperties: { type: 'number' } })
  byStatus!: Record<string, number>;
}
