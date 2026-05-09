import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SiteStatus } from '../../prisma-client';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

export class SiteMapSearchDto {
  @ApiProperty({ example: 'Skopje landfill', minLength: 2, maxLength: 200 })
  @IsString()
  @MinLength(2)
  @MaxLength(200)
  query!: string;

  @ApiPropertyOptional({ default: 20, minimum: 1, maximum: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit = 20;

  @ApiPropertyOptional({ description: 'User latitude for proximity boost' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lat?: number;

  @ApiPropertyOptional({ description: 'User longitude for proximity boost' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  lng?: number;

  @ApiPropertyOptional({
    description: 'Restrict hits to these workflow statuses (map filter parity)',
    enum: SiteStatus,
    isArray: true,
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(8)
  @Transform(({ value }) => {
    if (!Array.isArray(value)) {
      return value;
    }
    const allowed = new Set<string>(Object.values(SiteStatus));
    const out = value.filter((v: unknown) => typeof v === 'string' && allowed.has(v));
    return out.length > 0 ? out : undefined;
  })
  @IsEnum(SiteStatus, { each: true })
  statuses?: SiteStatus[];

  @ApiPropertyOptional({
    description: 'When true, include admin-archived sites in results',
  })
  @IsOptional()
  @IsBoolean()
  includeArchived?: boolean;

  @ApiPropertyOptional({
    description: 'Restrict to sites whose latest report category is one of these (API strings)',
    isArray: true,
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(8)
  @IsString({ each: true })
  @MaxLength(64, { each: true })
  pollutionTypes?: string[];
}
