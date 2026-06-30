import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches, MaxLength, MinLength } from 'class-validator';
import { IsStrongPassword } from '../../common/validators/password-strength.validator';

export class ChangePasswordDto {
  @ApiProperty({ description: 'Current account password' })
  @IsString()
  @MinLength(1)
  currentPassword!: string;

  @ApiProperty({ minLength: 8, maxLength: 72, example: 'NewStrong123!' })
  @IsString()
  @MinLength(8)
  @MaxLength(72)
  @Matches(/\d/, { message: 'newPassword must contain at least one number' })
  @Matches(/[A-Za-z]/, { message: 'newPassword must contain at least one letter' })
  @IsStrongPassword()
  newPassword!: string;
}
