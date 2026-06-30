import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CleanupEvidenceSubmitterDto {
  @ApiPropertyOptional({ nullable: true })
  displayLabel!: string | null;

  @ApiProperty()
  isDeleted!: boolean;

  @ApiProperty()
  isAnonymous!: boolean;
}

export class CleanupEvidenceItemDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  url!: string;

  @ApiProperty({ enum: ['RESOLUTION', 'CLEANUP_EVENT_AFTER', 'CLEANUP_EVENT_EVIDENCE'] })
  source!: 'RESOLUTION' | 'CLEANUP_EVENT_AFTER' | 'CLEANUP_EVENT_EVIDENCE';

  @ApiProperty()
  createdAt!: string;

  @ApiPropertyOptional({ nullable: true })
  caption!: string | null;

  @ApiPropertyOptional({ type: CleanupEvidenceSubmitterDto, nullable: true })
  submitter!: CleanupEvidenceSubmitterDto | null;

  @ApiPropertyOptional({ nullable: true })
  resolutionId!: string | null;

  @ApiPropertyOptional({ nullable: true })
  cleanupEventId!: string | null;
}

export class CleanupEvidenceListMetaDto {
  @ApiProperty()
  page!: number;

  @ApiProperty()
  limit!: number;

  @ApiProperty()
  total!: number;
}

export class CleanupEvidenceListResponseDto {
  @ApiProperty({ type: [CleanupEvidenceItemDto] })
  data!: CleanupEvidenceItemDto[];

  @ApiProperty({ type: CleanupEvidenceListMetaDto })
  meta!: CleanupEvidenceListMetaDto;
}
