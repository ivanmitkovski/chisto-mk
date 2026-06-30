import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsEnum } from 'class-validator';
import { AdminModerationCategory } from '../../prisma-client';

export class PatchModerationEmailPreferenceDto {
  @ApiProperty({ enum: AdminModerationCategory })
  @IsEnum(AdminModerationCategory)
  category!: AdminModerationCategory;

  @ApiProperty()
  @IsBoolean()
  enabled!: boolean;
}
