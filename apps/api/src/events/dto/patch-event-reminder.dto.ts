import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsDateString, IsOptional } from 'class-validator';

export class PatchEventReminderDto {
  @ApiProperty()
  @IsBoolean()
  reminderEnabled!: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  reminderAt?: string | null;
}
