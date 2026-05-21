import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsISO8601, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class PostSiteHistoryNoteDto {
  @ApiProperty({ description: 'Free-form admin note shown on the site timeline' })
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  note!: string;

  @ApiPropertyOptional({ description: 'Optional ISO-8601 timestamp for when the note occurred' })
  @IsOptional()
  @IsISO8601()
  occurredAt?: string;
}
