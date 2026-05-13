import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsOptional } from 'class-validator';
import { PaginationQueryDto20 } from '../../common/dto/pagination-query.dto';

export class ListNotificationsQueryDto extends PaginationQueryDto20 {
  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  onlyUnread?: boolean;
}
