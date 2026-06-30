import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ReportStatus } from '../../prisma-client';
import { IsEnum, IsString, Length, ValidateIf } from 'class-validator';

export class UpdateReportStatusDto {
  @ApiProperty({ enum: ReportStatus })
  @IsEnum(ReportStatus)
  status!: ReportStatus;

  @ApiPropertyOptional({
    description:
      'Required when moving a report to DELETED (moderation narrative). Ignored for other statuses.',
    maxLength: 500,
    example: 'Evidence was insufficient to verify this report.',
  })
  @ValidateIf((o: UpdateReportStatusDto) => o.status === ReportStatus.DELETED)
  @IsString()
  @Length(1, 500)
  reason?: string;
}
