import { ApiProperty } from '@nestjs/swagger';

export class SiteCommentLikeResponseDto {
  @ApiProperty()
  commentId!: string;

  @ApiProperty()
  likesCount!: number;

  @ApiProperty()
  isLikedByMe!: boolean;
}
