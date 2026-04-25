import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsInt,
  IsString,
  Matches,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { PRISMA_CUID_REGEX } from '../../common/validators/is-cuid.validator';

export class FieldBatchLiveImpactOpDto {
  @ApiProperty({ enum: ['live_impact_bags'] })
  @IsString()
  @IsIn(['live_impact_bags'])
  type!: 'live_impact_bags';

  @ApiProperty({ description: 'CleanupEvent id (Prisma cuid)' })
  @Matches(PRISMA_CUID_REGEX, { message: 'eventId must be a valid cuid' })
  eventId!: string;

  @ApiProperty({ minimum: 0, maximum: 9999 })
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(9999)
  reportedBagsCollected!: number;
}

export class FieldBatchDto {
  @ApiProperty({ type: [FieldBatchLiveImpactOpDto], maxItems: 20 })
  @IsArray()
  @ArrayMaxSize(20)
  @ValidateNested({ each: true })
  @Type(() => FieldBatchLiveImpactOpDto)
  operations!: FieldBatchLiveImpactOpDto[];
}

export class FieldBatchResultDto {
  applied!: number;
  failed!: number;
  errors?: Array<{ index: number; code: string; message: string }>;
}
