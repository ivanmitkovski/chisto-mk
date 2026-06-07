import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsDateString, IsInt, IsOptional, Max, Min } from 'class-validator';

export class AdminWeeklyRankingsQueryDto {
  @ApiPropertyOptional({ description: 'Max leaderboard rows (1–100)', default: 50, minimum: 1, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 50;

  @ApiPropertyOptional({
    description: 'Any date within the target Skopje week (ISO-8601). Defaults to the current week.',
  })
  @IsOptional()
  @IsDateString()
  weekStartsAt?: string;
}

export class AdminWeeklyLeaderboardEntryDto {
  @ApiProperty()
  rank!: number;

  @ApiProperty()
  userId!: string;

  @ApiProperty()
  displayName!: string;

  @ApiProperty()
  email!: string;

  @ApiProperty()
  weeklyPoints!: number;

  @ApiProperty()
  showOnLeaderboard!: boolean;
}

export class AdminWeeklyRankingsResponseDto {
  @ApiProperty({ description: 'Week start (Monday 00:00 Europe/Skopje), ISO-8601' })
  weekStartsAt!: string;

  @ApiProperty({ description: 'Week end (Sunday end of day Europe/Skopje), ISO-8601' })
  weekEndsAt!: string;

  @ApiProperty({ type: [AdminWeeklyLeaderboardEntryDto] })
  entries!: AdminWeeklyLeaderboardEntryDto[];
}
