import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsOptional,
  IsString,
  IsUrl,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { REPORT_CLEANUP_EFFORT_KEYS } from '../report-cleanup-effort';

export class CreateReportWithLocationDto {
  @ApiProperty({ description: 'Latitude of the report location', example: 41.6086 })
  @IsLatitude()
  latitude!: number;

  @ApiProperty({ description: 'Longitude of the report location', example: 21.7453 })
  @IsLongitude()
  longitude!: number;

  @ApiPropertyOptional({
    description: 'Free-text report description',
    example: 'Trash pile behind the bus station',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiPropertyOptional({
    description: 'Optional media attachment URLs (from POST /reports/upload)',
    type: [String],
    example: ['https://bucket.s3.region.amazonaws.com/reports/user123/photo.jpg'],
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(5)
  @IsUrl({}, { each: true })
  mediaUrls?: string[];

  @ApiPropertyOptional({
    description: 'Report category',
    enum: ['ILLEGAL_LANDFILL', 'WATER_POLLUTION', 'AIR_POLLUTION', 'INDUSTRIAL_WASTE', 'OTHER'],
  })
  @IsOptional()
  @IsString()
  @IsIn(['ILLEGAL_LANDFILL', 'WATER_POLLUTION', 'AIR_POLLUTION', 'INDUSTRIAL_WASTE', 'OTHER'])
  category?: string;

  @ApiPropertyOptional({
    description: 'Severity 1-5',
    minimum: 1,
    maximum: 5,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  severity?: number;

  @ApiPropertyOptional({
    description: 'Reverse-geocoded or user-confirmed place line (not the report narrative)',
    example: 'Skopje, Municipality of Centar',
    maxLength: 500,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  address?: string;

  @ApiPropertyOptional({
    description: 'Estimated cleanup team size for organizers',
    enum: REPORT_CLEANUP_EFFORT_KEYS,
  })
  @IsOptional()
  @IsString()
  @IsIn([...REPORT_CLEANUP_EFFORT_KEYS])
  cleanupEffort?: string;
}
