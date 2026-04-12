import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean } from 'class-validator';

export class MuteChatDto {
  @ApiProperty({ description: 'True to mute push notifications for this event chat' })
  @IsBoolean()
  muted!: boolean;
}
