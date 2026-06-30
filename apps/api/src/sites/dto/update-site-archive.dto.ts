import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateSiteArchiveDto {
  @ApiProperty({
    description: 'Whether site should be archived by admin moderation',
    example: true,
  })
  @IsBoolean()
  archived!: boolean;

  @ApiPropertyOptional({
    description: 'Archive reason required when archived=true',
    maxLength: 300,
    example: 'Resolved and hidden from default map view after municipal cleanup verification.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  reason?: string;
}
