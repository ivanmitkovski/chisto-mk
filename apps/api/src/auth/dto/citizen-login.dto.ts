import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class CitizenLoginDto {
  @ApiProperty({
    example: '+38970123456',
    description: 'Phone number in E.164 format',
  })
  @IsString()
  @Matches(/^\+[1-9]\d{7,14}$/, {
    message: 'phoneNumber must be in E.164 format (e.g. +38970123456)',
  })
  phoneNumber!: string;

  @ApiProperty({ minLength: 8, maxLength: 72, example: 'StrongPass123!' })
  @IsString()
  @MinLength(8)
  @MaxLength(72)
  password!: string;

  @ApiPropertyOptional({
    description: 'If true, refresh token lasts longer (e.g. 30 days). If false, short-lived (e.g. 1 day).',
    default: true,
  })
  @IsOptional()
  @IsBoolean()
  rememberMe?: boolean;
}
