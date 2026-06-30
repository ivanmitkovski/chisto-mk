import { ApiProperty } from '@nestjs/swagger';
import {
  IsEmail,
  IsISO8601,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { IsStrongPassword } from '../../common/validators/password-strength.validator';
import { SanitizePlainText } from '../../common/sanitize/sanitize-transform.decorator';

export class RegisterDto {
  @ApiProperty({ example: 'Ivan' })
  @IsString()
  @MinLength(2)
  @MaxLength(60)
  @SanitizePlainText()
  firstName!: string;

  @ApiProperty({ example: 'Mitkovski' })
  @IsString()
  @MinLength(2)
  @MaxLength(60)
  @SanitizePlainText()
  lastName!: string;

  @ApiProperty({ example: 'citizen@chisto.mk' })
  @IsEmail()
  email!: string;

  @ApiProperty({
    example: '+38970123456',
    description: 'Phone number in E.164 format for future verification flows',
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
  @Matches(/\d/, { message: 'Password must contain at least one number' })
  @Matches(/[A-Za-z]/, { message: 'Password must contain at least one letter' })
  @IsStrongPassword()
  password!: string;

  @ApiProperty({ example: '2026-06-01T12:00:00.000Z', description: 'ISO-8601 when terms were accepted on device' })
  @IsISO8601()
  termsAcceptedAt!: string;

  @ApiProperty({ example: '1', description: 'Must match server TERMS_VERSION' })
  @IsString()
  @MinLength(1)
  @MaxLength(32)
  termsVersion!: string;

  @ApiProperty({ required: false, example: '2026-06-01' })
  @IsOptional()
  @IsISO8601()
  privacyAcceptedAt?: string;

  @ApiProperty({ required: false, description: 'Stable per-install device identifier.', maxLength: 128 })
  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceId?: string;
}
