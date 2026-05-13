import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsEnum, IsOptional, IsString } from 'class-validator';
import { Role, UserStatus } from '../../prisma-client';

import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';

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
}
