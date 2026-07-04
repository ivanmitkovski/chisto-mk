import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsBoolean,
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

export class NewsGalleryItemDto {
  @ApiProperty()
  @IsString()
  mediaId!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  caption?: string;
}

export class NewsBodyBlockDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  id?: string;

  @ApiProperty({ enum: ['paragraph', 'html', 'heading', 'list', 'image', 'video', 'gallery'] })
  @IsIn(['paragraph', 'html', 'heading', 'list', 'image', 'video', 'gallery'])
  type!: 'paragraph' | 'html' | 'heading' | 'list' | 'image' | 'video' | 'gallery';

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  text?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  html?: string;

  @ApiPropertyOptional({ enum: [2, 3] })
  @IsOptional()
  @IsIn([2, 3])
  level?: 2 | 3;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  ordered?: boolean;

  @ApiPropertyOptional({ description: 'List item strings or gallery media items' })
  @IsOptional()
  items?: string[] | NewsGalleryItemDto[];

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

/** Draft saves: allow empty locale fields; publish validates in the service layer. */
export class DraftNewsLocaleContentDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  excerpt?: string;

  @ApiPropertyOptional({ type: [NewsBodyBlockDto] })
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => NewsBodyBlockDto)
  body?: NewsBodyBlock[];
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

export class DraftNewsTranslationsDto {
  @ApiProperty({ type: DraftNewsLocaleContentDto })
  @ValidateNested()
  @Type(() => DraftNewsLocaleContentDto)
  en!: DraftNewsLocaleContentDto;

  @ApiProperty({ type: DraftNewsLocaleContentDto })
  @ValidateNested()
  @Type(() => DraftNewsLocaleContentDto)
  mk!: DraftNewsLocaleContentDto;

  @ApiProperty({ type: DraftNewsLocaleContentDto })
  @ValidateNested()
  @Type(() => DraftNewsLocaleContentDto)
  sq!: DraftNewsLocaleContentDto;
}

export class CreateNewsPostDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  slug?: string;

  @ApiProperty({ enum: ['release', 'partnership', 'community', 'product'] })
  @IsIn(['release', 'partnership', 'community', 'product'])
  category!: NewsCategoryApi;

  @ApiProperty({ type: DraftNewsTranslationsDto })
  @ValidateNested()
  @Type(() => DraftNewsTranslationsDto)
  translations!: DraftNewsTranslationsDto;
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

  @ApiPropertyOptional({ type: DraftNewsTranslationsDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => DraftNewsTranslationsDto)
  translations?: DraftNewsTranslationsDto;

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsString()
  scheduledAt?: string | null;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  featured?: boolean;

  @ApiPropertyOptional({
    description: 'ISO timestamp of the post updatedAt the client last loaded; rejects with 409 on mismatch',
  })
  @IsOptional()
  @IsString()
  expectedUpdatedAt?: string;
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

  @ApiPropertyOptional({ enum: ['release', 'partnership', 'community', 'product'] })
  @IsOptional()
  @IsIn(['release', 'partnership', 'community', 'product'])
  category?: 'release' | 'partnership' | 'community' | 'product';
}

export class UploadNewsMediaQueryDto {
  @ApiProperty({ enum: ['cover', 'inline_image', 'inline_video'] })
  @IsIn(['cover', 'inline_image', 'inline_video'])
  kind!: 'cover' | 'inline_image' | 'inline_video';
}

export class UpdateNewsMediaAltDto {
  @ApiPropertyOptional()
  @IsOptional()
  altText?: Partial<Record<'en' | 'mk' | 'sq', string>>;
}

export class AdminListNewsPostsQueryDto {
  @ApiPropertyOptional({ enum: ['draft', 'scheduled', 'published', 'archived'] })
  @IsOptional()
  @IsIn(['draft', 'scheduled', 'published', 'archived'])
  status?: 'draft' | 'scheduled' | 'published' | 'archived';

  @ApiPropertyOptional({ enum: ['release', 'partnership', 'community', 'product'] })
  @IsOptional()
  @IsIn(['release', 'partnership', 'community', 'product'])
  category?: 'release' | 'partnership' | 'community' | 'product';

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  q?: string;

  @ApiPropertyOptional({ default: 20 })
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

  @ApiPropertyOptional({ enum: ['publishedAt', 'updatedAt', 'title'] })
  @IsOptional()
  @IsIn(['publishedAt', 'updatedAt', 'title'])
  sort?: 'publishedAt' | 'updatedAt' | 'title';
}
