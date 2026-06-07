import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsEnum, IsIn, IsOptional, IsString } from 'class-validator';
import { Role, UserStatus } from '../../prisma-client';

import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';

export enum AdminUsersSortField {
  LAST_ACTIVE = 'lastActiveAt',
  NAME = 'name',
  EMAIL = 'email',
  POINTS = 'pointsBalance',
  CREATED = 'createdAt',
}

export enum AdminUsersSortDir {
  ASC = 'asc',
  DESC = 'desc',
}

export class ListAdminUsersQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ enum: UserStatus })
  @IsOptional()
  @IsEnum(UserStatus)
  status?: UserStatus;

  @ApiPropertyOptional({ enum: Role })
  @IsOptional()
  @IsEnum(Role)
  role?: Role;

  @ApiPropertyOptional({ description: 'Filter users last active before this ISO date' })
  @IsOptional()
  @IsDateString()
  lastActiveBefore?: string;

  @ApiPropertyOptional({ description: 'Filter users last active after this ISO date' })
  @IsOptional()
  @IsDateString()
  lastActiveAfter?: string;

  @ApiPropertyOptional({ enum: AdminUsersSortField, default: AdminUsersSortField.CREATED })
  @IsOptional()
  @IsEnum(AdminUsersSortField)
  sort?: AdminUsersSortField;

  @ApiPropertyOptional({ enum: AdminUsersSortDir, default: AdminUsersSortDir.DESC })
  @IsOptional()
  @IsIn([AdminUsersSortDir.ASC, AdminUsersSortDir.DESC])
  dir?: AdminUsersSortDir;
}
