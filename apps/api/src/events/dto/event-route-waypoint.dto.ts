import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

/** Single route waypoint for create / PATCH event (North Macedonia bbox enforced upstream if needed). */
export class EventRouteWaypointDto {
  @ApiProperty({ description: 'Latitude (WGS84)' })
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude!: number;

  @ApiProperty({ description: 'Longitude (WGS84)' })
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude!: number;

  @ApiPropertyOptional({ maxLength: 120 })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  label?: string;
}

export class EventRouteWaypointsBodyDto {
  @ApiProperty({ type: [EventRouteWaypointDto], maxItems: 24 })
  @IsArray()
  @ArrayMaxSize(24)
  @ValidateNested({ each: true })
  @Type(() => EventRouteWaypointDto)
  waypoints!: EventRouteWaypointDto[];
}
