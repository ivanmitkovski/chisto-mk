import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';
import type { NewsBodyBlock, NewsCategoryApi, NewsTranslations } from '../types/news.types';

export class NewsBodyBlockDto {
  @ApiProperty({ enum: ['paragraph', 'image', 'video'] })
  @IsIn(['paragraph', 'image', 'video'])
  type!: 'paragraph' | 'image' | 'video';

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  text?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  mediaId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  caption?: string;
}

export class NewsLocaleContentDto {
  @ApiProperty()
  @IsString()
  @MinLength(1)
  title!: string;

  @ApiProperty()
  @IsString()
  @MinLength(1)
  excerpt!: string;

  @ApiProperty({ type: [NewsBodyBlockDto] })
  @ValidateNested({ each: true })
  @Type(() => NewsBodyBlockDto)
  body!: NewsBodyBlock[];
}

export class NewsTranslationsDto implements NewsTranslations {
  @ApiProperty({ type: NewsLocaleContentDto })
  @ValidateNested()
  @Type(() => NewsLocaleContentDto)
  en!: NewsLocaleContentDto;

  @ApiProperty({ type: NewsLocaleContentDto })
  @ValidateNested()
  @Type(() => NewsLocaleContentDto)
  mk!: NewsLocaleContentDto;

  @ApiProperty({ type: NewsLocaleContentDto })
  @ValidateNested()
  @Type(() => NewsLocaleContentDto)
  sq!: NewsLocaleContentDto;
}

export class CreateNewsPostDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  slug?: string;

  @ApiProperty({ enum: ['release', 'partnership', 'community', 'product'] })
  @IsIn(['release', 'partnership', 'community', 'product'])
  category!: NewsCategoryApi;

  @ApiProperty({ type: NewsTranslationsDto })
  @ValidateNested()
  @Type(() => NewsTranslationsDto)
  translations!: NewsTranslationsDto;
}

export class UpdateNewsPostDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  slug?: string;

  @ApiPropertyOptional({ enum: ['release', 'partnership', 'community', 'product'] })
  @IsOptional()
  @IsIn(['release', 'partnership', 'community', 'product'])
  category?: NewsCategoryApi;

  @ApiPropertyOptional({ type: NewsTranslationsDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => NewsTranslationsDto)
  translations?: NewsTranslationsDto;

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsString()
  scheduledAt?: string | null;
}

export class ListNewsPostsQueryDto {
  @ApiPropertyOptional({ default: 'en' })
  @IsOptional()
  @IsString()
  locale?: string;

  @ApiPropertyOptional({ default: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  offset?: number;
}

export class UploadNewsMediaQueryDto {
  @ApiProperty({ enum: ['cover', 'inline_image', 'inline_video'] })
  @IsIn(['cover', 'inline_image', 'inline_video'])
  kind!: 'cover' | 'inline_image' | 'inline_video';
}
