import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class Disable2FADto {
  @ApiProperty({ description: 'Current password to confirm identity' })
  @IsString()
  @MinLength(8)
  @MaxLength(72)
  password!: string;
}
