import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';
import { SanitizePlainText } from '../../common/sanitize/sanitize-transform.decorator';

export class EditEventChatMessageDto {
  @ApiProperty({ example: 'Updated message', minLength: 1, maxLength: 2000 })
  @SanitizePlainText()
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  body!: string;
}
