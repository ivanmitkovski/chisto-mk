import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches, MaxLength, MinLength } from 'class-validator';
import { IsStrongPassword } from '../../common/validators/password-strength.validator';

export class ResetPasswordConfirmDto {
  @ApiProperty({
    example: '+38970123456',
    description: 'Phone number in E.164 format',
  })
  @IsString()
  @Matches(/^\+[1-9]\d{7,14}$/, {
    message: 'phoneNumber must be in E.164 format (e.g. +38970123456)',
  })
  phoneNumber!: string;

  @ApiProperty({ example: '1234', minLength: 4, maxLength: 4 })
  @IsString()
  @MinLength(4)
  @MaxLength(4)
  @Matches(/^\d{4}$/, { message: 'code must be exactly 4 digits' })
  code!: string;

  @ApiProperty({ minLength: 8, maxLength: 72, example: 'NewStrong123!' })
  @IsString()
  @MinLength(8)
  @MaxLength(72)
  @Matches(/\d/, { message: 'newPassword must contain at least one number' })
  @Matches(/[A-Za-z]/, { message: 'newPassword must contain at least one letter' })
  @IsStrongPassword()
  newPassword!: string;
}
