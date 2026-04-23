import { ApiProperty } from '@nestjs/swagger';

export type ImpactReceiptCompleteness =
  | 'in_progress'
  | 'full'
  | 'partial_missing_after'
  | 'partial_missing_evidence'
  | 'partial_missing_after_and_evidence';

export class EventImpactReceiptEvidenceItemDto {
  @ApiProperty()
  id!: string;

  @ApiProperty({ enum: ['before', 'after', 'field'] })
  kind!: string;

  @ApiProperty({ description: 'Short-lived signed URL' })
  imageUrl!: string;

  @ApiProperty({ nullable: true })
  caption!: string | null;

  @ApiProperty()
  createdAt!: string;
}

export class EventImpactReceiptResponseDto {
  @ApiProperty()
  eventId!: string;

  @ApiProperty()
  title!: string;

  @ApiProperty({ description: 'Human-readable site label (address or description)' })
  siteLabel!: string;

  @ApiProperty()
  scheduledAt!: string;

  @ApiProperty({ nullable: true })
  endAt!: string | null;

  @ApiProperty({ enum: ['upcoming', 'inProgress', 'completed', 'cancelled'] })
  lifecycleStatus!: string;

  @ApiProperty()
  participantCount!: number;

  @ApiProperty()
  checkedInCount!: number;

  @ApiProperty({ description: 'Canonical bags from live metric (0 if unset)' })
  reportedBagsCollected!: number;

  @ApiProperty({ nullable: true })
  bagsUpdatedAt!: string | null;

  @ApiProperty({ type: [EventImpactReceiptEvidenceItemDto] })
  evidence!: EventImpactReceiptEvidenceItemDto[];

  @ApiProperty({ type: [String], description: 'Signed after-cleanup photo URLs' })
  afterImageUrls!: string[];

  @ApiProperty({
    enum: [
      'in_progress',
      'full',
      'partial_missing_after',
      'partial_missing_evidence',
      'partial_missing_after_and_evidence',
    ],
  })
  completeness!: ImpactReceiptCompleteness;

  @ApiProperty({ description: 'ISO timestamp when this payload was assembled' })
  asOf!: string;

  @ApiProperty({ description: 'Organizer display name when present' })
  organizerName!: string;
}
