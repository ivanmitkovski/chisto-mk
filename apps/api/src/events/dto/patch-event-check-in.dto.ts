import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean } from 'class-validator';

export class PatchEventCheckInDto {
  @ApiProperty({ description: 'Whether attendee QR check-in is active' })
  @IsBoolean()
  isOpen!: boolean;
}
