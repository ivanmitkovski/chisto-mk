import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';
import { SanitizePlainText } from '../../../common/sanitize/sanitize-transform.decorator';

export class CreateSiteResolutionDto {
  @ApiProperty({
    description: 'Cleanup evidence photo URLs (from POST /sites/:siteId/resolutions/upload)',
    type: [String],
    minItems: 1,
    maxItems: 5,
  })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(5)
  @IsString({ each: true })
  @MaxLength(2048, { each: true })
  @Matches(/^https:\/\/.+/i, { each: true, message: 'Each media URL must be an https URL' })
  mediaUrls!: string[];

  @ApiPropertyOptional({
    description: 'Optional note about the cleanup',
    maxLength: 500,
  })
  @IsOptional()
  @SanitizePlainText()
  @IsString()
  @MaxLength(500)
  note?: string;
}
