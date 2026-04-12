import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean } from 'class-validator';

export class PinEventChatMessageDto {
  @ApiProperty({ description: 'True to pin, false to unpin' })
  @IsBoolean()
  pinned!: boolean;
}
