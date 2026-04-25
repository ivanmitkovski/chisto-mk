import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  Allow,
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { PRISMA_CUID_REGEX } from '../../common/validators/is-cuid.validator';

const EVIDENCE_KINDS = ['before', 'after', 'field'] as const;
const ROUTE_SEGMENT_STATUSES = ['open', 'claimed', 'completed'] as const;
const ATTENDEE_CHECK_IN = ['checkedIn', 'notCheckedIn'] as const;

/** Single evidence thumbnail in mobile event payload. */
export class EventMobileEvidenceStripItemDto {
  @ApiProperty({ description: 'Evidence row id (Prisma cuid)' })
  @Matches(PRISMA_CUID_REGEX, { message: 'id must be a valid cuid' })
  id!: string;

  @ApiProperty({ enum: EVIDENCE_KINDS })
  @IsString()
  @IsIn([...EVIDENCE_KINDS])
  kind!: string;

  @ApiProperty()
  @IsString()
  imageUrl!: string;

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  caption!: string | null;

  @ApiProperty({ type: String, format: 'date-time' })
  @IsString()
  createdAt!: string;
}

/** Route segment row for field mode / map (mobile contract). */
export class EventMobileRouteSegmentDto {
  @ApiProperty({ description: 'Route segment id (Prisma cuid)' })
  @Matches(PRISMA_CUID_REGEX, { message: 'id must be a valid cuid' })
  id!: string;

  @ApiProperty()
  @IsInt()
  @Min(0)
  sortOrder!: number;

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  label!: string | null;

  @ApiProperty()
  @IsNumber()
  latitude!: number;

  @ApiProperty()
  @IsNumber()
  longitude!: number;

  @ApiProperty({ enum: ROUTE_SEGMENT_STATUSES })
  @IsString()
  @IsIn([...ROUTE_SEGMENT_STATUSES])
  status!: string;

  @ApiPropertyOptional({ nullable: true, description: 'User id when claimed (Prisma cuid)' })
  @IsOptional()
  @ValidateIf((_, v: unknown) => v != null)
  @Matches(PRISMA_CUID_REGEX, { message: 'claimedByUserId must be a valid cuid' })
  claimedByUserId!: string | null;

  @ApiPropertyOptional({ type: String, format: 'date-time', nullable: true })
  @IsOptional()
  @IsString()
  claimedAt!: string | null;

  @ApiPropertyOptional({ type: String, format: 'date-time', nullable: true })
  @IsOptional()
  @IsString()
  completedAt!: string | null;
}

/**
 * Mobile-facing event shape returned by list/detail/join/check-in mutations.
 * Validated for contract stability; nested lists use DTO classes with class-validator.
 */
export class EventMobileResponseDto {
  @ApiProperty({ description: 'CleanupEvent id (Prisma cuid)' })
  @Matches(PRISMA_CUID_REGEX, { message: 'id must be a valid cuid' })
  id!: string;

  @ApiProperty()
  @IsString()
  @MaxLength(4000)
  title!: string;

  @ApiProperty()
  @IsString()
  @MaxLength(20_000)
  description!: string;

  @ApiProperty({ description: 'Mobile category key (camelCase)' })
  @IsString()
  category!: string;

  @ApiProperty()
  @IsBoolean()
  moderationApproved!: boolean;

  @ApiProperty()
  @IsString()
  moderationStatus!: string;

  @ApiProperty({ description: 'Site id (Prisma cuid)' })
  @Matches(PRISMA_CUID_REGEX, { message: 'siteId must be a valid cuid' })
  siteId!: string;

  @ApiProperty()
  @IsString()
  siteName!: string;

  @ApiProperty()
  @IsString()
  siteImageUrl!: string;

  @ApiProperty({ description: 'Distance from request point to site (km), 0 when coords absent' })
  @IsNumber()
  @Min(0)
  siteDistanceKm!: number;

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsNumber()
  siteLat!: number | null;

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsNumber()
  siteLng!: number | null;

  @ApiProperty({ description: 'Organizer user id (Prisma cuid)' })
  @Matches(PRISMA_CUID_REGEX, { message: 'organizerId must be a valid cuid' })
  organizerId!: string;

  @ApiProperty()
  @IsString()
  organizerName!: string;

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsString()
  organizerAvatarUrl!: string | null;

  @ApiProperty({ type: String, format: 'date-time' })
  @IsString()
  scheduledAt!: string;

  @ApiPropertyOptional({ type: String, format: 'date-time', nullable: true })
  @IsOptional()
  @IsString()
  endAt!: string | null;

  @ApiProperty({ description: 'Mobile lifecycle key' })
  @IsString()
  status!: string;

  @ApiProperty()
  @IsInt()
  @Min(0)
  participantCount!: number;

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsInt()
  @Min(0)
  maxParticipants!: number | null;

  @ApiProperty()
  @IsBoolean()
  isJoined!: boolean;

  @ApiProperty({ type: [String], description: 'Gear keys (camelCase strings)' })
  @IsArray()
  @IsString({ each: true })
  gear!: string[];

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsString()
  scale!: string | null;

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsString()
  difficulty!: string | null;

  @ApiProperty()
  @IsBoolean()
  reminderEnabled!: boolean;

  @ApiPropertyOptional({ type: String, format: 'date-time', nullable: true })
  @IsOptional()
  @IsString()
  reminderAt!: string | null;

  @ApiProperty({ type: [String] })
  @IsArray()
  @IsString({ each: true })
  afterImagePaths!: string[];

  @ApiProperty({ type: String, format: 'date-time' })
  @IsString()
  createdAt!: string;

  @ApiPropertyOptional({ nullable: true, description: 'Check-in session id when set (Prisma cuid)' })
  @IsOptional()
  @ValidateIf((_, v: unknown) => v != null)
  @Matches(PRISMA_CUID_REGEX, { message: 'activeCheckInSessionId must be a valid cuid' })
  activeCheckInSessionId!: string | null;

  @ApiProperty()
  @IsBoolean()
  isCheckInOpen!: boolean;

  @ApiProperty()
  @IsInt()
  @Min(0)
  checkedInCount!: number;

  @ApiProperty({ enum: ATTENDEE_CHECK_IN })
  @IsString()
  @IsIn([...ATTENDEE_CHECK_IN])
  attendeeCheckInStatus!: string;

  @ApiPropertyOptional({ type: String, format: 'date-time', nullable: true })
  @IsOptional()
  @IsString()
  attendeeCheckedInAt!: string | null;

  @ApiPropertyOptional({ nullable: true, description: 'Recurrence rule JSON (opaque to clients)' })
  @IsOptional()
  @Allow()
  recurrenceRule!: unknown | null;

  @ApiPropertyOptional({ nullable: true, description: 'Parent series event id (Prisma cuid)' })
  @IsOptional()
  @ValidateIf((_, v: unknown) => v != null)
  @Matches(PRISMA_CUID_REGEX, { message: 'parentEventId must be a valid cuid' })
  parentEventId!: string | null;

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsInt()
  @Min(0)
  recurrenceIndex!: number | null;

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsInt()
  @Min(0)
  recurrenceSeriesTotal!: number | null;

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsInt()
  @Min(0)
  recurrenceSeriesPosition!: number | null;

  @ApiPropertyOptional({ nullable: true, description: 'Previous occurrence id (Prisma cuid)' })
  @IsOptional()
  @ValidateIf((_, v: unknown) => v != null)
  @Matches(PRISMA_CUID_REGEX, { message: 'recurrencePrevEventId must be a valid cuid' })
  recurrencePrevEventId!: string | null;

  @ApiPropertyOptional({ nullable: true, description: 'Next occurrence id (Prisma cuid)' })
  @IsOptional()
  @ValidateIf((_, v: unknown) => v != null)
  @Matches(PRISMA_CUID_REGEX, { message: 'recurrenceNextEventId must be a valid cuid' })
  recurrenceNextEventId!: string | null;

  @ApiProperty()
  @IsInt()
  @Min(0)
  liveReportedBagsCollected!: number;

  @ApiPropertyOptional({ type: String, format: 'date-time', nullable: true })
  @IsOptional()
  @IsString()
  liveMetricUpdatedAt!: string | null;

  @ApiProperty({ type: [EventMobileRouteSegmentDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => EventMobileRouteSegmentDto)
  routeSegments!: EventMobileRouteSegmentDto[];

  @ApiProperty({ type: [EventMobileEvidenceStripItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => EventMobileEvidenceStripItemDto)
  evidenceStrip!: EventMobileEvidenceStripItemDto[];
}
