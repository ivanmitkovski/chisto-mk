import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MinLength, MaxLength } from 'class-validator';

export class Complete2FALoginDto {
  @ApiProperty({ description: 'Short-lived temp token from admin login when 2FA is required' })
  @IsString()
  tempToken!: string;

  @ApiProperty({
    description: '6-digit TOTP code or backup code (alphanumeric)',
    minLength: 6,
    maxLength: 32,
  })
  @IsString()
  @MinLength(6)
  @MaxLength(32)
  code!: string;

  @ApiPropertyOptional({
    description: 'Stable browser/device identifier used to keep one active admin session per device.',
    maxLength: 128,
  })
  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceId?: string;
}
