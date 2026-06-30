import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsEmail, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class AdminLoginDto {
  @ApiProperty({ example: 'admin@chisto.mk' })
  @IsEmail()
  email!: string;

  @ApiProperty({ minLength: 8, maxLength: 72, example: 'StrongPass123!' })
  @IsString()
  @MinLength(8)
  @MaxLength(72)
  password!: string;

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
