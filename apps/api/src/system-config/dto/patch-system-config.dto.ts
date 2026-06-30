import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsArray, IsString, MinLength, ValidateNested } from 'class-validator';

export class SystemConfigEntryDto {
  @ApiProperty()
  @IsString()
  @MinLength(1)
  key!: string;

  @ApiProperty()
  @IsString()
  value!: string;
}

export class PatchSystemConfigDto {
  @ApiProperty({ type: [SystemConfigEntryDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SystemConfigEntryDto)
  entries!: SystemConfigEntryDto[];
}
