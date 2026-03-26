import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateSiteCommentDto {
  @ApiProperty({ example: 'Thanks for reporting this. I can help this weekend.' })
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  body!: string;

  @ApiProperty({ required: false, description: 'Parent comment id for nested reply' })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(64)
  parentId?: string;
}
