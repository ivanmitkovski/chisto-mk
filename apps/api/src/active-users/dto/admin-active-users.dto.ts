import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsEnum, IsInt, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';
import { DevicePlatform, UserActivityEventType, AdminAlertMetric, AdminAlertComparator } from '../../prisma-client';

export class ActiveUsersListQueryDto {
  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ default: 25 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 25;

  @ApiPropertyOptional({ enum: ['online', 'away', 'offline'] })
  @IsOptional()
  @IsString()
  status?: 'online' | 'away' | 'offline';

  @ApiPropertyOptional({ enum: DevicePlatform })
  @IsOptional()
  @IsEnum(DevicePlatform)
  platform?: DevicePlatform;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  search?: string;
}

export class ActivityFeedQueryDto {
  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ default: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 50;

  @ApiPropertyOptional({ enum: UserActivityEventType })
  @IsOptional()
  @IsEnum(UserActivityEventType)
  type?: UserActivityEventType;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  search?: string;
}

export class CreateAdminAlertRuleDto {
  @ApiProperty({ enum: AdminAlertMetric })
  @IsEnum(AdminAlertMetric)
  metric!: AdminAlertMetric;

  @ApiProperty({ default: 100 })
  @Type(() => Number)
  @IsNumber()
  threshold!: number;

  @ApiPropertyOptional({ default: 300 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  windowSeconds?: number;

  @ApiPropertyOptional({ enum: AdminAlertComparator, default: AdminAlertComparator.GT })
  @IsOptional()
  @IsEnum(AdminAlertComparator)
  comparator?: AdminAlertComparator;
}

export class UpdateAdminAlertRuleDto {
  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  threshold?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;
}
