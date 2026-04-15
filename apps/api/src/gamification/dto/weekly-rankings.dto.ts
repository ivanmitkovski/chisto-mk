import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

export class WeeklyRankingsQueryDto {
  @ApiPropertyOptional({ description: 'Max leaderboard rows (1–100)', default: 50, minimum: 1, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 50;
}

export class WeeklyLeaderboardEntryDto {
  @ApiProperty()
  rank!: number;

  @ApiProperty()
  userId!: string;

  @ApiProperty()
  displayName!: string;

  @ApiProperty()
  weeklyPoints!: number;

  @ApiProperty()
  isCurrentUser!: boolean;
}

export class WeeklyRankingsResponseDto {
  @ApiProperty({ description: 'Week start (Monday 00:00 Europe/Skopje), ISO-8601' })
  weekStartsAt!: string;

  @ApiProperty({ description: 'Week end (Sunday end of day Europe/Skopje), ISO-8601' })
  weekEndsAt!: string;

  @ApiProperty({ type: [WeeklyLeaderboardEntryDto] })
  entries!: WeeklyLeaderboardEntryDto[];

  @ApiProperty({ nullable: true, description: '1-based rank among users with weekly points > 0; null if none' })
  myRank!: number | null;

  @ApiProperty({
    description: 'Current user’s sum of positive point credits for this Skopje week (all sources)',
  })
  myWeeklyPoints!: number;
}
