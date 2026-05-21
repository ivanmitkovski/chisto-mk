import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class UnsubscribePostDto {
  @ApiPropertyOptional({ description: 'Signed unsubscribe token from email link' })
  @IsOptional()
  @IsString()
  @MaxLength(2048)
  token?: string;
}
