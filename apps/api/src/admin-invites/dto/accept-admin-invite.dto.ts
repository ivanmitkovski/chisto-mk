import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, Matches, MaxLength, MinLength, ValidateIf } from 'class-validator';
import { IsStrongPassword } from '../../common/validators/password-strength.validator';

export class AcceptAdminInviteDto {
  @ApiProperty()
  @IsString()
  @MinLength(1)
  @MaxLength(64)
  id!: string;

  @ApiProperty()
  @IsString()
  @MinLength(16)
  @MaxLength(256)
  token!: string;

  @ApiProperty({ minLength: 8, maxLength: 72 })
  @IsString()
  @MinLength(8)
  @MaxLength(72)
  @Matches(/\d/, { message: 'Password must contain at least one number' })
  @Matches(/[A-Za-z]/, { message: 'Password must contain at least one letter' })
  @IsStrongPassword()
  password!: string;

  @ApiProperty({ example: '+38970123456' })
  @IsString()
  @Matches(/^\+[1-9]\d{7,14}$/, {
    message: 'phoneNumber must be in E.164 format (e.g. +38970123456)',
  })
  phoneNumber!: string;

  @ApiPropertyOptional({
    description: 'Required when completing TOTP enrollment during invite accept; omit to skip 2FA',
    example: '123456',
  })
  @IsOptional()
  @ValidateIf((o: AcceptAdminInviteDto) => o.totpCode != null && String(o.totpCode).trim() !== '')
  @IsString()
  @MinLength(6)
  @MaxLength(8)
  totpCode?: string;

  @ApiPropertyOptional({ maxLength: 128 })
  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceId?: string;
}
