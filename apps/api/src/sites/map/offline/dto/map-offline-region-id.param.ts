import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class MapOfflineRegionIdParam {
  @ApiProperty({ example: 'mk-north-west' })
  @IsString()
  @MinLength(1)
  @MaxLength(64)
  @Matches(/^[a-z0-9][a-z0-9._-]*$/i)
  regionId!: string;
}
