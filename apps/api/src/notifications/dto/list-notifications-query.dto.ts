import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional } from 'class-validator';
import { StrictBoolean } from '../../common/transformers/strict-boolean.transformer';
import { PaginationQueryDto20 } from '../../common/dto/pagination-query.dto';

export class ListNotificationsQueryDto extends PaginationQueryDto20 {
  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @StrictBoolean()
  @IsBoolean()
  onlyUnread?: boolean;
}
