import { ApiProperty } from '@nestjs/swagger';

export class SiteMediaItemResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  reportId!: string;

  @ApiProperty()
  createdAt!: string;

  @ApiProperty()
  url!: string;
}

export class SiteMediaListMetaResponseDto {
  @ApiProperty()
  page!: number;

  @ApiProperty()
  limit!: number;

  @ApiProperty()
  total!: number;

  @ApiProperty({ required: false })
  truncated?: boolean;
}

export class SiteMediaListResponseDto {
  @ApiProperty({ type: [SiteMediaItemResponseDto] })
  data!: SiteMediaItemResponseDto[];

  @ApiProperty({ type: SiteMediaListMetaResponseDto })
  meta!: SiteMediaListMetaResponseDto;
}
