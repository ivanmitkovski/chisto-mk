import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class RefreshTokenDto {
  @ApiProperty({ description: 'Refresh token from the previous auth response' })
  @IsNotEmpty({ message: 'refreshToken must not be empty' })
  @IsString()
  refreshToken!: string;
}
