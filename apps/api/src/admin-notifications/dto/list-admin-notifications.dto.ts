import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsEnum, IsOptional } from 'class-validator';
import { StrictBoolean } from '../../common/transformers/strict-boolean.transformer';
import { PaginationQueryDto20 } from '../../common/dto/pagination-query.dto';
import { AdminNotificationCategory } from '../../prisma-client';

export class ListAdminNotificationsQueryDto extends PaginationQueryDto20 {
  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @StrictBoolean()
  @IsBoolean()
  onlyUnread?: boolean;

  @ApiPropertyOptional({ enum: AdminNotificationCategory })
  @IsOptional()
  @IsEnum(AdminNotificationCategory)
  category?: AdminNotificationCategory;
}
