import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, MinLength, MaxLength } from 'class-validator';

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

  @ApiPropertyOptional({
    description: 'When true, issue a long-lived refresh session (30 days). When false, session expires in 1 day.',
  })
  @IsOptional()
  @IsBoolean()
  rememberMe?: boolean;
}
