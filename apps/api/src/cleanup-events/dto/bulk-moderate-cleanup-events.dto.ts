import { ApiProperty } from '@nestjs/swagger';
import { ArrayMaxSize, IsArray, IsIn, IsString, IsUUID, Matches, MaxLength, MinLength, ValidateIf } from 'class-validator';
import { PRISMA_CUID_REGEX } from '../../common/validators/is-cuid.validator';

export class BulkModerateCleanupEventsDto {
  @ApiProperty({ type: [String], maxItems: 50, description: 'Cleanup event ids (Prisma cuid)' })
  @IsArray()
  @ArrayMaxSize(50)
  @IsString({ each: true })
  @Matches(PRISMA_CUID_REGEX, { each: true, message: 'each value in eventIds must be a valid cuid' })
  eventIds!: string[];

  @ApiProperty({ enum: ['APPROVED', 'DECLINED'] })
  @IsIn(['APPROVED', 'DECLINED'])
  action!: 'APPROVED' | 'DECLINED';

  @ApiProperty({
    required: false,
    description: 'Required when action is DECLINED (shared reason for all rows in this job).',
  })
  @ValidateIf((o: BulkModerateCleanupEventsDto) => o.action === 'DECLINED')
  @IsString()
  @MinLength(3)
  @MaxLength(2000)
  declineReason?: string;

  @ApiProperty({ description: 'Client-generated UUID; duplicate values return 409 for this actor.' })
  @IsUUID('4')
  clientJobId!: string;
}
