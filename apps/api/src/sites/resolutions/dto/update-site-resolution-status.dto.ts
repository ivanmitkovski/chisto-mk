import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SiteResolutionStatus } from '../../../prisma-client';
import { IsEnum, IsString, Length, ValidateIf } from 'class-validator';

export class UpdateSiteResolutionStatusDto {
  @ApiProperty({ enum: [SiteResolutionStatus.APPROVED, SiteResolutionStatus.REJECTED] })
  @IsEnum(SiteResolutionStatus)
  status!: SiteResolutionStatus;

  @ApiPropertyOptional({
    description: 'Required when rejecting a resolution submission.',
    maxLength: 500,
  })
  @ValidateIf((o: UpdateSiteResolutionStatusDto) => o.status === SiteResolutionStatus.REJECTED)
  @IsString()
  @Length(1, 500)
  reason?: string;
}
