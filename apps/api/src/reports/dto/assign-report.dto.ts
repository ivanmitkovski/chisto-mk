import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, Length, Matches } from 'class-validator';
import { StrictBoolean } from '../../common/transformers/strict-boolean.transformer';

export class AssignReportDto {
  @ApiPropertyOptional({
    description: 'Target moderator user id; omit to assign to the authenticated moderator',
    example: 'cm1234567890abcdefghijkl',
  })
  @IsOptional()
  @IsString()
  @Length(20, 40)
  @Matches(/^[A-Za-z0-9_-]+$/, {
    message: 'moderatorId must be an alphanumeric id (e.g. CUID)',
  })
  moderatorId?: string;

  @ApiPropertyOptional({
    description: 'When true, clears the current assignee without changing report status',
    default: false,
  })
  @StrictBoolean()
  @IsOptional()
  @IsBoolean()
  unassign?: boolean;
}

export class AssignReportResponseDto {
  @ApiProperty()
  reportId!: string;

  @ApiProperty({ nullable: true })
  assignedModeratorId!: string | null;

  @ApiProperty({ nullable: true })
  assignedModeratorName!: string | null;

  @ApiProperty({ enum: ['NEW', 'IN_REVIEW', 'APPROVED', 'DELETED'] })
  status!: 'NEW' | 'IN_REVIEW' | 'APPROVED' | 'DELETED';
}
