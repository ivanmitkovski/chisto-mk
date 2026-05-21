import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class UpdateHomeLocationDto {
  @ApiProperty({ example: 41.9981, description: 'WGS84 latitude' })
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude!: number;

  @ApiProperty({ example: 21.4254, description: 'WGS84 longitude' })
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude!: number;

  @ApiPropertyOptional({ example: 'Skopje, North Macedonia', maxLength: 200 })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  label?: string;
}
