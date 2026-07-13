import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Matches } from 'class-validator';
import { PRISMA_CUID_REGEX } from '../../common/validators/is-cuid.validator';
import { SiteStatus } from '../../prisma-client';

export class SitePublicShareReporterDto {
  @ApiProperty({ nullable: true, description: 'Public display name (no email/phone/user id)' })
  displayLabel!: string | null;

  @ApiProperty({ nullable: true, description: 'Stable redirect URL for reporter avatar (`/sites/:id/share-avatar`)' })
  avatarUrl!: string | null;

  @ApiProperty()
  isDeleted!: boolean;

  @ApiProperty({ description: 'True when identity should be shown as localized Anonymous' })
  isAnonymous!: boolean;
}

export class SitePublicShareEventDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  title!: string;

  @ApiProperty({ description: 'ISO-8601 scheduled start' })
  scheduledAt!: string;

  @ApiProperty({ description: 'Location line derived from site address' })
  city!: string;

  @ApiProperty()
  participantCount!: number;

  @ApiProperty({ nullable: true })
  maxParticipants!: number | null;

  @ApiProperty({ description: 'EcoEventLifecycleStatus' })
  status!: string;
}

export class SitePublicShareCardResponseDto {
  @ApiProperty({ description: 'Site id (Prisma cuid)' })
  @Matches(PRISMA_CUID_REGEX, { message: 'id must be a valid cuid' })
  id!: string;

  @ApiProperty({ description: 'Headline from canonical hero report or first approved report' })
  title!: string;

  @ApiProperty({ description: 'City / area line (same rules as mobile siteName)' })
  siteLabel!: string;

  @ApiProperty({ enum: SiteStatus })
  status!: SiteStatus;

  @ApiPropertyOptional({ nullable: true })
  description!: string | null;

  @ApiPropertyOptional({ nullable: true })
  address!: string | null;

  @ApiProperty()
  latitude!: number;

  @ApiProperty()
  longitude!: number;

  @ApiProperty({
    type: [String],
    description:
      'Stable share-media redirect URLs (`/sites/:id/share-media/:index`); each request 302s to a fresh signed GET',
  })
  mediaUrls!: string[];

  @ApiPropertyOptional({ nullable: true, description: 'Report category code' })
  category!: string | null;

  @ApiPropertyOptional({ nullable: true, description: 'Severity 1–5' })
  severity!: number | null;

  @ApiPropertyOptional({ nullable: true, description: 'ReportCleanupEffort enum value' })
  cleanupEffort!: string | null;

  @ApiProperty()
  upvotesCount!: number;

  @ApiProperty()
  commentsCount!: number;

  @ApiProperty()
  sharesCount!: number;

  @ApiProperty()
  savesCount!: number;

  @ApiPropertyOptional({ nullable: true, description: 'ISO-8601 primary report createdAt' })
  reportedAt!: string | null;

  @ApiPropertyOptional({ type: () => SitePublicShareReporterDto, nullable: true })
  reporter!: SitePublicShareReporterDto | null;

  @ApiProperty({ type: [SitePublicShareEventDto] })
  events!: SitePublicShareEventDto[];

  @ApiProperty({
    type: [String],
    description:
      'Stable share-evidence redirect URLs when cleaned (`/sites/:id/share-evidence/:index`)',
  })
  cleanupEvidenceUrls!: string[];

  @ApiPropertyOptional({
    nullable: true,
    description:
      'First stable media/evidence redirect URL for in-page use; OG tags use opengraph-image.tsx instead',
  })
  ogImageUrl!: string | null;
}
