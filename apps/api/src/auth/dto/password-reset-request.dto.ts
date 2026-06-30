import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsOptional, IsString, Matches, ValidateIf } from 'class-validator';

export class PasswordResetRequestDto {
  @ApiPropertyOptional({ example: '+38970123456' })
  @ValidateIf((o: PasswordResetRequestDto) => !o.email)
  @IsString()
  @Matches(/^\+[1-9]\d{7,14}$/, {
    message: 'phoneNumber must be in E.164 format (e.g. +38970123456)',
  })
  @IsOptional()
  phoneNumber?: string;

  @ApiPropertyOptional({ example: 'citizen@chisto.mk' })
  @ValidateIf((o: PasswordResetRequestDto) => !o.phoneNumber)
  @IsEmail()
  @IsOptional()
  email?: string;
}
