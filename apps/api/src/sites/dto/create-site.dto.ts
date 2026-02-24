import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsLatitude, IsLongitude, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateSiteDto {
  @ApiProperty({ example: 41.9981, description: 'Site latitude' })
  @IsLatitude()
  latitude!: number;

  @ApiProperty({ example: 21.4254, description: 'Site longitude' })
  @IsLongitude()
  longitude!: number;

  @ApiPropertyOptional({
    example: 'Illegal dumping near the riverbank.',
    description: 'Short report context for the created site.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;
}
