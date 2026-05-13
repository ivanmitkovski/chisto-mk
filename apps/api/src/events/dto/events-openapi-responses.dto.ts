import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { EventMobileResponseDto } from './event-mobile-response.dto';

/** Paginated `GET /events` response. */
export class EventsListMetaDto {
  @ApiProperty()
  hasMore!: boolean;

  @ApiProperty({ nullable: true, type: String })
  nextCursor!: string | null;
}

export class EventsListResponseDto {
  @ApiProperty({ type: [EventMobileResponseDto] })
  data!: EventMobileResponseDto[];

  @ApiProperty({ type: EventsListMetaDto })
  meta!: EventsListMetaDto;
}

/** POST /events/search — same meta as list plus title suggestions. */
export class EventSearchResponseDto {
  @ApiProperty({ type: [EventMobileResponseDto] })
  data!: EventMobileResponseDto[];

  @ApiProperty({ type: EventsListMetaDto })
  meta!: EventsListMetaDto;

  @ApiProperty({ type: [String], description: 'Up to 3 matching event titles' })
  suggestions!: string[];
}

export class ConflictingEventPreviewDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  title!: string;

  @ApiProperty({ type: String, format: 'date-time' })
  scheduledAt!: string;
}

export class ScheduleConflictPreviewResponseDto {
  @ApiProperty()
  hasConflict!: boolean;

  @ApiPropertyOptional({ type: ConflictingEventPreviewDto })
  conflictingEvent?: ConflictingEventPreviewDto;
}

export class LiveImpactSnapshotResponseDto {
  @ApiProperty()
  eventId!: string;

  @ApiProperty()
  participantCount!: number;

  @ApiProperty()
  checkedInCount!: number;

  @ApiProperty()
  reportedBagsCollected!: number;

  @ApiProperty()
  estimatedKgCollected!: number;

  @ApiProperty({ type: String, format: 'date-time' })
  updatedAt!: string;
}

export class EvidencePhotoResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  kind!: string;

  @ApiProperty()
  imageUrl!: string;

  @ApiProperty({ nullable: true })
  caption!: string | null;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt!: string;
}

export class DeleteEvidenceResponseDto {
  @ApiProperty({ enum: [true] })
  ok!: true;
}

export class JoinEventResponseDto extends EventMobileResponseDto {
  @ApiProperty({ description: 'Gamification points awarded for this join (0 if replay)' })
  pointsAwarded!: number;
}

