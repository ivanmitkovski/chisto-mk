import { ApiProperty } from '@nestjs/swagger';

export class SiteCoReporterRowResponseDto {
  @ApiProperty({ description: 'Opaque stable row id (not raw userId for non-moderators)' })
  id!: string;

  @ApiProperty()
  firstName!: string;

  @ApiProperty()
  lastName!: string;

  @ApiProperty()
  displayName!: string;

  @ApiProperty()
  isDeleted!: boolean;

  @ApiProperty({ nullable: true })
  avatarUrl!: string | null;

  @ApiProperty()
  reportedAt!: string;

  @ApiProperty()
  isOriginalReporter!: boolean;
}

export class SiteCoReportersMetaResponseDto {
  @ApiProperty()
  page!: number;

  @ApiProperty()
  limit!: number;

  @ApiProperty()
  total!: number;

  @ApiProperty()
  hasMore!: boolean;
}

export class SiteCoReportersListResponseDto {
  @ApiProperty({ type: [SiteCoReporterRowResponseDto] })
  data!: SiteCoReporterRowResponseDto[];

  @ApiProperty({ type: SiteCoReportersMetaResponseDto })
  meta!: SiteCoReportersMetaResponseDto;
}
