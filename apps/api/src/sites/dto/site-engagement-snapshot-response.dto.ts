import { ApiProperty } from '@nestjs/swagger';

/** Shape returned by upvote/save/share mutations. */
export class SiteEngagementSnapshotResponseDto {
  @ApiProperty()
  siteId!: string;

  @ApiProperty()
  upvotesCount!: number;

  @ApiProperty()
  commentsCount!: number;

  @ApiProperty()
  savesCount!: number;

  @ApiProperty()
  sharesCount!: number;

  @ApiProperty()
  isUpvotedByMe!: boolean;

  @ApiProperty()
  isSavedByMe!: boolean;
}
