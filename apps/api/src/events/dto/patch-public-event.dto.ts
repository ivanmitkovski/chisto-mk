import { ApiPropertyOptional } from '@nestjs/swagger';
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
} from 'class-validator';
import { MOBILE_CATEGORY_KEYS } from '../events-mobile.mapper';

export class PatchPublicEventDto {
  @ApiPropertyOptional({ minLength: 3, maxLength: 200 })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  title?: string;

  @ApiPropertyOptional({ maxLength: 10_000 })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MaxLength(10_000)
  description?: string;

  @ApiPropertyOptional({ enum: MOBILE_CATEGORY_KEYS })
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @IsIn(MOBILE_CATEGORY_KEYS)
  category?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsDateString()
  scheduledAt?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsDateString()
  endAt?: string | null;

  @ApiPropertyOptional({ minimum: 2, maximum: 5000 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(2)
  @Max(5000)
  maxParticipants?: number | null;

  @ApiPropertyOptional({ type: [String] })
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
}
