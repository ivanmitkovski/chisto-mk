import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';

export const CHECK_IN_RISK_SIGNAL_ACTIONS = ['resolve', 'dismiss'] as const;

export class PatchCheckInRiskSignalDto {
  @ApiProperty({ enum: CHECK_IN_RISK_SIGNAL_ACTIONS })
  @IsIn([...CHECK_IN_RISK_SIGNAL_ACTIONS])
  action!: (typeof CHECK_IN_RISK_SIGNAL_ACTIONS)[number];
}
