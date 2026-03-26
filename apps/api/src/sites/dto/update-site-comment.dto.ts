import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class UpdateSiteCommentDto {
  @ApiProperty({
    example: 'Updated comment text',
    description: 'Updated comment body',
    minLength: 1,
    maxLength: 500,
  })
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  body!: string;
}
