import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsEnum, IsOptional } from 'class-validator';
import { PaginationQueryDto20 } from '../../common/dto/pagination-query.dto';
import { AdminNotificationCategory } from '../../prisma-client';

export class ListAdminNotificationsQueryDto extends PaginationQueryDto20 {
  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  onlyUnread?: boolean;

  @ApiPropertyOptional({ enum: AdminNotificationCategory })
  @IsOptional()
  @IsEnum(AdminNotificationCategory)
  category?: AdminNotificationCategory;
}
