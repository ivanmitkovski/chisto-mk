import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsDateString,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
  Matches,
  ValidateNested,
} from 'class-validator';
import { MOBILE_CATEGORY_KEYS } from '../events-mobile.mapper';
import { EventRouteWaypointDto } from './event-route-waypoint.dto';

export class CreatePublicEventDto {
  @ApiProperty()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MinLength(1)
  siteId!: string;

  @ApiProperty({ minLength: 3, maxLength: 200 })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  title!: string;

  @ApiProperty({ maxLength: 10_000 })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MaxLength(10_000)
  description!: string;

  @ApiProperty({ enum: MOBILE_CATEGORY_KEYS })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @IsIn(MOBILE_CATEGORY_KEYS)
  category!: string;

  @ApiProperty({ description: 'Event start (ISO 8601)' })
  @IsDateString()
  scheduledAt!: string;

  @ApiPropertyOptional({ description: 'Event end (ISO 8601)' })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsDateString()
  endAt?: string;

  @ApiPropertyOptional({ minimum: 2, maximum: 5000 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(2)
  @Max(5000)
  maxParticipants?: number;

  @ApiPropertyOptional({ type: [String], description: 'Gear keys e.g. trashBags' })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsString({ each: true })
  gear?: string[];

  @ApiPropertyOptional({ enum: ['small', 'medium', 'large', 'massive'] })
  @IsOptional()
  @IsString()
  @IsIn(['small', 'medium', 'large', 'massive'])
  scale?: string;

  @ApiPropertyOptional({ enum: ['easy', 'moderate', 'hard'] })
  @IsOptional()
  @IsString()
  @IsIn(['easy', 'moderate', 'hard'])
  difficulty?: string;

  @ApiPropertyOptional({
    description:
      'RFC 5545 RRULE string (without the "RRULE:" prefix). Max 52 occurrences enforced server-side.',
    example: 'FREQ=WEEKLY;BYDAY=SA',
  })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MaxLength(500)
  @Matches(/^FREQ=(DAILY|WEEKLY|MONTHLY|YEARLY)/, {
    message: 'recurrenceRule must start with FREQ=DAILY|WEEKLY|MONTHLY|YEARLY',
  })
  recurrenceRule?: string;

  @ApiPropertyOptional({
    description: 'How many occurrences to create (1–52). Ignored when recurrenceRule is absent.',
    minimum: 2,
    maximum: 52,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(2)
  @Max(52)
  recurrenceCount?: number;

  @ApiPropertyOptional({
    type: [EventRouteWaypointDto],
    description: 'Optional cleanup route waypoints (max 24)',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(24)
  @ValidateNested({ each: true })
  @Type(() => EventRouteWaypointDto)
  routeWaypoints?: EventRouteWaypointDto[];
}
