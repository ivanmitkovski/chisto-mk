import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
} from 'class-validator';

export class CreateReportDto {
  @ApiProperty({
    description: 'Site identifier to attach the report to',
    example: 'cm1234567890abcdefghijkl',
  })
  @IsString()
  siteId!: string;

  @ApiPropertyOptional({
    description: 'Free-text report description',
    example: 'Trash pile behind the bus station',
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
}
