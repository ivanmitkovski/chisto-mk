import { ApiProperty } from '@nestjs/swagger';

export class ReportCapacityDto {
  @ApiProperty({ description: 'Number of standard report credits currently available' })
  creditsAvailable!: number;

  @ApiProperty({ description: 'Whether emergency report allowance is currently available' })
  emergencyAvailable!: boolean;

  @ApiProperty({ description: 'Emergency cooldown window in days' })
  emergencyWindowDays!: number;

  @ApiProperty({
    description: 'Seconds until emergency allowance is available again; null when already available',
    nullable: true,
  })
  retryAfterSeconds!: number | null;

  @ApiProperty({
    description: 'UTC instant (ISO-8601) when emergency reporting becomes available again; null when not on cooldown',
    nullable: true,
  })
  nextEmergencyReportAvailableAt!: string | null;

  @ApiProperty({
    description:
      'Epoch milliseconds when emergency allowance refills (same instant as nextEmergencyReportAvailableAt); null when not on cooldown',
    nullable: true,
    required: false,
  })
  nextRefillAtMs?: number | null;

  @ApiProperty({ description: 'Human guidance on how to unlock more reports' })
  unlockHint!: string;
}

