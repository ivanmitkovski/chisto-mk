import { ApiProperty } from '@nestjs/swagger';

export class ProcessMemoryDto {
  @ApiProperty({ example: 128 })
  rssMb!: number;

  @ApiProperty({ example: 64 })
  heapUsedMb!: number;

  @ApiProperty({ example: 96 })
  heapTotalMb!: number;
}

export class OperationsMetricsSnapshotDto {
  @ApiProperty({ example: 12000 })
  requestsTotal!: number;

  @ApiProperty({ example: 12 })
  requestsFailed!: number;

  @ApiProperty({ example: 45 })
  p50Ms!: number;

  @ApiProperty({ example: 120 })
  p95Ms!: number;

  @ApiProperty({ example: 250 })
  p99Ms!: number;

  @ApiProperty({ example: 5000 })
  pushSendsTotal!: number;

  @ApiProperty({ example: 4800 })
  pushSendsSuccess!: number;

  @ApiProperty({ example: 150 })
  pushSendsFailure!: number;

  @ApiProperty({ example: 50 })
  pushSendsRevoked!: number;

  @ApiProperty({ example: 3 })
  pushQueueDepth!: number;

  @ApiProperty({ example: 1 })
  pushActiveLeases!: number;

  @ApiProperty({ example: 2 })
  pushDeadLetterCount!: number;

  @ApiProperty({ example: 8000 })
  mapRequestsTotal!: number;

  @ApiProperty({ example: 0.82 })
  mapCacheHitRate!: number;

  @ApiProperty({ example: 12 })
  mapOutboxPending!: number;

  @ApiProperty({ example: 0 })
  mapOutboxFailed!: number;

  @ApiProperty({ example: 1200 })
  feedRequestsTotal!: number;

  @ApiProperty({ example: 0.75 })
  feedCacheHitRate!: number;

  @ApiProperty({ example: 3 })
  reportSideEffectFailedTotal!: number;

  @ApiProperty({ example: 0 })
  emailQueueDepth!: number;

  @ApiProperty({ example: 0 })
  emailDeadLetterCount!: number;

  @ApiProperty({ example: 0 })
  pushDispatchSkippedFcmNotReady!: number;

  @ApiProperty({ example: 0 })
  pushDispatchSkippedNoTokens!: number;

  @ApiProperty({ example: 0 })
  pushDispatchSkippedWriterNull!: number;

  @ApiProperty({ type: ProcessMemoryDto })
  processMemory!: ProcessMemoryDto;

  @ApiProperty({ example: '2026-06-07T12:00:00.000Z' })
  capturedAt!: string;
}
