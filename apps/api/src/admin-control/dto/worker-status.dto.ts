import { ApiProperty } from '@nestjs/swagger';

export class WorkerStatusDto {
  @ApiProperty({ example: 'push-delivery' })
  name!: string;

  @ApiProperty({ example: true })
  running!: boolean;

  @ApiProperty({ example: 5000 })
  intervalMs!: number;

  @ApiProperty({ example: '2026-06-07T10:00:00.000Z' })
  startedAt!: string;

  @ApiProperty({ nullable: true, example: '2026-06-07T12:00:00.000Z' })
  lastRunAt!: string | null;

  @ApiProperty({ nullable: true, example: '2026-06-07T12:00:00.000Z' })
  lastSuccessAt!: string | null;

  @ApiProperty({ nullable: true, example: null })
  lastError!: string | null;

  @ApiProperty({ example: false })
  stale!: boolean;
}

export class WorkerStatusListDto {
  @ApiProperty({ type: [WorkerStatusDto] })
  workers!: WorkerStatusDto[];

  @ApiProperty({
    description: 'Worker heartbeats are per ECS task / process replica',
    example: true,
  })
  perReplica!: boolean;
}
