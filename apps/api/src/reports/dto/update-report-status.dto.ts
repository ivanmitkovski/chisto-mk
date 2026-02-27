import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ReportStatus } from '@prisma/client';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateReportStatusDto {
  @ApiProperty({ enum: ReportStatus })
  @IsEnum(ReportStatus)
  status!: ReportStatus;

  @ApiPropertyOptional({
    description: 'Optional human-readable moderation reason or rejection explanation',
    maxLength: 500,
    example: 'Evidence was insufficient to verify this report.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
