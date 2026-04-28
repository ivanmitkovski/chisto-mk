import { ApiProperty } from '@nestjs/swagger';

export class SiteUpvoterRowResponseDto {
  @ApiProperty()
  userId!: string;

  @ApiProperty()
  displayName!: string;

  @ApiProperty({ nullable: true })
  avatarUrl!: string | null;

  @ApiProperty()
  upvotedAt!: string;
}

export class SiteUpvotersMetaResponseDto {
  @ApiProperty()
  page!: number;

  @ApiProperty()
  limit!: number;

  @ApiProperty()
  total!: number;

  @ApiProperty()
  hasMore!: boolean;
}

export class SiteUpvotersListResponseDto {
  @ApiProperty({ type: [SiteUpvoterRowResponseDto] })
  data!: SiteUpvoterRowResponseDto[];

  @ApiProperty({ type: SiteUpvotersMetaResponseDto })
  meta!: SiteUpvotersMetaResponseDto;
}
