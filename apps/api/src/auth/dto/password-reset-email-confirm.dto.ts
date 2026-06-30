import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, Matches, MaxLength, MinLength } from 'class-validator';
import { IsStrongPassword } from '../../common/validators/password-strength.validator';

export class PasswordResetEmailConfirmDto {
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  @MaxLength(254)
  email!: string;

  @ApiProperty({ example: '123456', minLength: 6, maxLength: 6 })
  @IsString()
  @MinLength(6)
  @MaxLength(6)
  @Matches(/^\d{6}$/, { message: 'code must be exactly 6 digits' })
  code!: string;

  @ApiProperty({ minLength: 8, maxLength: 72 })
  @IsString()
  @MinLength(8)
  @MaxLength(72)
  @Matches(/\d/, { message: 'newPassword must contain at least one number' })
  @Matches(/[A-Za-z]/, { message: 'newPassword must contain at least one letter' })
  @IsStrongPassword()
  newPassword!: string;
}
