import { ApiProperty } from '@nestjs/swagger';

/** Recursive comment node for `GET/POST /sites/:id/comments`. */
export class SiteCommentTreeNodeResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty({ nullable: true })
  parentId!: string | null;

  @ApiProperty()
  body!: string;

  @ApiProperty()
  createdAt!: string;

  @ApiProperty()
  authorId!: string;

  @ApiProperty()
  authorName!: string;

  @ApiProperty({ required: false, nullable: true })
  authorAvatarUrl?: string | null;

  @ApiProperty()
  likesCount!: number;

  @ApiProperty()
  isLikedByMe!: boolean;

  @ApiProperty({ type: () => [SiteCommentTreeNodeResponseDto] })
  replies!: SiteCommentTreeNodeResponseDto[];

  @ApiProperty()
  repliesCount!: number;
}

export class SiteCommentsListMetaResponseDto {
  @ApiProperty()
  page!: number;

  @ApiProperty()
  limit!: number;

  @ApiProperty()
  total!: number;

  @ApiProperty({ required: false })
  truncated?: boolean;
}

export class SiteCommentsListResponseDto {
  @ApiProperty({ type: [SiteCommentTreeNodeResponseDto] })
  data!: SiteCommentTreeNodeResponseDto[];

  @ApiProperty({ type: SiteCommentsListMetaResponseDto })
  meta!: SiteCommentsListMetaResponseDto;
}
