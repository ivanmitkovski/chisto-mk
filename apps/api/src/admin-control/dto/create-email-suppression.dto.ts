import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsIn, IsOptional } from 'class-validator';

const SUPPRESSION_REASONS = ['ManualSuppression', 'HardBounce', 'SpamComplaint'] as const;

export class CreateEmailSuppressionDto {
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  email!: string;

  @ApiPropertyOptional({ enum: SUPPRESSION_REASONS, default: 'ManualSuppression' })
  @IsOptional()
  @IsIn([...SUPPRESSION_REASONS])
  reason?: (typeof SUPPRESSION_REASONS)[number];
}
