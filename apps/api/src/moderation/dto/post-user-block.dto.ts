import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class PostUserBlockDto {
  @ApiProperty({ description: 'User id to block' })
  @IsString()
  @MinLength(1)
  blockedUserId!: string;
}
