import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CreateReportDto {
  @ApiProperty({
    description: 'Site identifier to attach the report to',
    example: 'cm1234567890abcdefghijkl',
  })
  @IsString()
  siteId!: string;

  @ApiProperty({
    description: 'Short headline for lists and moderation',
    example: 'Trash pile behind the bus station',
    maxLength: 120,
  })
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  title!: string;

  @ApiPropertyOptional({
    description: 'Optional extra context',
    example: 'Additional details for moderators.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiPropertyOptional({
    description: 'Optional media attachments',
    type: [String],
    example: ['https://example.com/photo-1.jpg'],
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(5)
  @IsUrl({}, { each: true })
  mediaUrls?: string[];

  @ApiPropertyOptional({
    description:
      'Optional reporter identifier when the report is created on behalf of an authenticated user',
  })
  @IsOptional()
  @IsString()
  reporterId?: string;
}
