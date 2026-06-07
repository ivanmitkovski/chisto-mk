import { ApiProperty } from '@nestjs/swagger';

export class ReportSideEffectPendingCountDto {
  @ApiProperty({ description: 'Report side-effect outbox rows awaiting processing' })
  pendingCount!: number;
}
