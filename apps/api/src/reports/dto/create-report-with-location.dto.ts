import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

import { GeoPointLatitudeLongitudeDto } from '../../common/dto/geo-point.dto';
import { REPORT_CLEANUP_EFFORT_KEYS } from '../report-cleanup-effort';

export class CreateReportWithLocationDto extends GeoPointLatitudeLongitudeDto {
  // SECURITY: All fields are length/type bounded for DB alignment and to limit abuse; whitelist via global ValidationPipe.
  @ApiProperty({
    description: 'Short headline for lists and moderation',
    example: 'Illegal dump behind the bus station',
    maxLength: 120,
  })
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  title!: string;

  @ApiPropertyOptional({
    description: 'Optional extra context (not the headline)',
    example: 'Waste has been accumulating for several weeks.',
    maxLength: 500,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiPropertyOptional({
    description: 'Optional media attachment URLs (from POST /reports/upload)',
    type: [String],
    maxItems: 5,
    example: ['https://bucket.s3.region.amazonaws.com/reports/user123/photo.jpg'],
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(5)
  @IsString({ each: true })
  @MaxLength(2048, { each: true })
  /** S3 virtual-hosted URLs from POST /reports/upload — avoid @IsUrl quirks on some clients. */
  @Matches(/^https:\/\/.+/i, { each: true, message: 'Each media URL must be an https URL' })
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
