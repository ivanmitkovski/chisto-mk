import { ApiProperty } from '@nestjs/swagger';
import { ArrayMaxSize, IsArray, IsIn, IsString, IsUUID, MaxLength, MinLength, ValidateIf } from 'class-validator';

export class BulkModerateCleanupEventsDto {
  @ApiProperty({ type: [String], maxItems: 50 })
  @IsArray()
  @ArrayMaxSize(50)
  @IsUUID('4', { each: true })
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
