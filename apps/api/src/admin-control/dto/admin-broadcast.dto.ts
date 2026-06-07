import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsIn, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateBroadcastDto {
  @ApiProperty()
  @IsString()
  @MinLength(1)
  title!: string;

  @ApiProperty()
  @IsString()
  @MinLength(1)
  body!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  type?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  deeplink?: string;

  @ApiProperty({ enum: ['all', 'active', 'area', 'users'] })
  @IsIn(['all', 'active', 'area', 'users'])
  audience!: 'all' | 'active' | 'area' | 'users';

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  audienceUserIds?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  scheduledAt?: string;
}

export class UpdateBroadcastDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MinLength(1)
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MinLength(1)
  body?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  type?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  deeplink?: string;

  @ApiPropertyOptional({ enum: ['all', 'active', 'area', 'users'] })
  @IsOptional()
  @IsIn(['all', 'active', 'area', 'users'])
  audience?: 'all' | 'active' | 'area' | 'users';

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  audienceUserIds?: string[];

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsString()
  scheduledAt?: string | null;
}
