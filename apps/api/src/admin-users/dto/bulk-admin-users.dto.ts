import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsEnum, IsIn, IsOptional, IsString, ArrayMinSize } from 'class-validator';
import { Role } from '../../prisma-client';

export class BulkAdminUsersDto {
  @ApiProperty({ type: [String], example: ['user-1', 'user-2'] })
  @IsArray()
  @IsString({ each: true })
  @ArrayMinSize(1)
  userIds!: string[];

  @ApiProperty({ enum: ['suspend', 'activate', 'changeRole'] })
  @IsIn(['suspend', 'activate', 'changeRole'])
  action!: 'suspend' | 'activate' | 'changeRole';

  @ApiPropertyOptional({ enum: Role })
  @IsOptional()
  @IsEnum(Role)
  role?: Role;
}
