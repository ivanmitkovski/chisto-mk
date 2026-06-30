import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class RefreshTokenDto {
  @ApiProperty({ description: 'Refresh token from the previous auth response' })
  @IsNotEmpty({ message: 'refreshToken must not be empty' })
  @IsString()
  refreshToken!: string;

  @ApiPropertyOptional({
    description: 'Stable per-install device identifier for session deduplication.',
    maxLength: 128,
  })
  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceId?: string;
}
