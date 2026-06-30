import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean } from 'class-validator';

export class EventChatTypingDto {
  @ApiProperty({ description: 'Whether the user is currently typing in this chat' })
  @IsBoolean()
  typing!: boolean;
}
