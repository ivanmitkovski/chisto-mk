import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class VerifyOtpDto {
  @ApiProperty({
    example: '+38970123456',
    description: 'Phone number in E.164 format',
  })
  @IsString()
  @Matches(/^\+[1-9]\d{7,14}$/, {
    message: 'phoneNumber must be in E.164 format (e.g. +38970123456)',
  })
  phoneNumber!: string;

  @ApiProperty({
    example: '1234',
    description: '4-digit code received via SMS',
    minLength: 4,
    maxLength: 4,
  })
  @IsString()
  @MinLength(4)
  @MaxLength(4)
  @Matches(/^\d{4}$/, { message: 'code must be exactly 4 digits' })
  code!: string;
}
