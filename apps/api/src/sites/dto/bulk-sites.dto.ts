import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SiteStatus } from '../../prisma-client';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';

export class BulkSitesDto {
  @ApiProperty({ enum: ['set_status', 'set_archived'], example: 'set_status' })
  @IsEnum(['set_status', 'set_archived'])
  action!: 'set_status' | 'set_archived';

  @ApiProperty({ type: [String], maxItems: 200 })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(200)
  @IsString({ each: true })
  @MinLength(10, { each: true })
  @MaxLength(40, { each: true })
  @Type(() => String)
  siteIds!: string[];

  @ApiPropertyOptional({ description: 'Target status when action is set_status' })
  @ValidateIf((o: BulkSitesDto) => o.action === 'set_status')
  @IsEnum(SiteStatus)
  status?: SiteStatus;

  @ApiPropertyOptional({ description: 'Archive flag when action is set_archived' })
  @ValidateIf((o: BulkSitesDto) => o.action === 'set_archived')
  @IsBoolean()
  archived?: boolean;

  @ApiPropertyOptional({
    description: 'Idempotency key for safe retries (stored in audit metadata only).',
    maxLength: 128,
  })
  @IsOptional()
  @IsString()
  @MaxLength(128)
  idempotencyKey?: string;
}
