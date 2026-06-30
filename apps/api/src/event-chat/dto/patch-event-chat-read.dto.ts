import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class PatchEventChatReadDto {
  @ApiPropertyOptional({
    description: 'Last message id the user has read (clears unread for messages at or before it)',
  })
  @IsOptional()
  @IsString()
  lastReadMessageId?: string | null;
}
