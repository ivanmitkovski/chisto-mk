import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';
import { IsStrongPassword } from '../../common/validators/password-strength.validator';

export class PasswordResetEmailConfirmDto {
  @ApiProperty({ description: 'Opaque token from the password reset email link' })
  @IsString()
  @MinLength(16)
  @MaxLength(256)
  token!: string;

  @ApiProperty({ minLength: 8, maxLength: 72 })
  @IsString()
  @MinLength(8)
  @MaxLength(72)
  @IsStrongPassword()
  newPassword!: string;
}
