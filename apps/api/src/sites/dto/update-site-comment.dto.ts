import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';
import { SanitizePlainText } from '../../common/sanitize/sanitize-transform.decorator';

export class UpdateSiteCommentDto {
  @ApiProperty({
    example: 'Updated comment text',
    description: 'Updated comment body',
    minLength: 1,
    maxLength: 500,
  })
  @SanitizePlainText()
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  body!: string;
}
