import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class BeginInviteMfaDto {
  @ApiProperty()
  @IsString()
  @MinLength(1)
  @MaxLength(64)
  id!: string;

  @ApiProperty({ description: 'Single-use invite token from the email link' })
  @IsString()
  @MinLength(16)
  @MaxLength(256)
  token!: string;
}
