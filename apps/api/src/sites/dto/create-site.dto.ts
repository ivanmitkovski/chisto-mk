import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

import { GeoPointLatitudeLongitudeDto } from '../../common/dto/geo-point.dto';

export class CreateSiteDto extends GeoPointLatitudeLongitudeDto {
  @ApiPropertyOptional({
    example: 'Illegal dumping near the riverbank.',
    description: 'Short report context for the created site.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;
}
