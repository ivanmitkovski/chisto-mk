import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class ValidateAdminInviteQueryDto {
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
}
