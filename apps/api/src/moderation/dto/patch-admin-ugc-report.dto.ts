import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export const UGC_MODERATION_ACTIONS = [
  'mark_reviewed',
  'dismiss',
  'escalate',
  'hide_subject',
  'restore_subject',
] as const;

export class PatchAdminUgcReportDto {
  @ApiProperty({ enum: UGC_MODERATION_ACTIONS })
  @IsIn([...UGC_MODERATION_ACTIONS])
  action!: (typeof UGC_MODERATION_ACTIONS)[number];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;

  @ApiPropertyOptional({ description: 'Policy reason for audit trail (required for dismiss/escalate/hide/restore)' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  policyReason?: string;
}
