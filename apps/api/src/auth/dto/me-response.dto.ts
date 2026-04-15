import { ApiProperty } from '@nestjs/swagger';
import { Role, UserStatus } from '../../prisma-client';

export class MeResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  firstName!: string;

  @ApiProperty()
  lastName!: string;

  @ApiProperty()
  email!: string;

  @ApiProperty()
  phoneNumber!: string;

  @ApiProperty({ enum: Role })
  role!: Role;

  @ApiProperty({ enum: UserStatus })
  status!: UserStatus;

  @ApiProperty()
  isPhoneVerified!: boolean;

  @ApiProperty({ description: 'Spendable points balance' })
  pointsBalance!: number;

  @ApiProperty({
    description:
      'Lifetime XP (level curve). Includes first-report awards and, when implemented, eco-action approval (+50) and completion (+100) via PointTransaction.',
  })
  totalPointsEarned!: number;

  @ApiProperty()
  totalPointsSpent!: number;

  @ApiProperty()
  mfaEnabled!: boolean;

  @ApiProperty({ nullable: true })
  avatarUrl!: string | null;

  @ApiProperty({ description: 'Server-computed level (1-based)' })
  level!: number;

  @ApiProperty({ description: 'Progress within current level, 0–1' })
  levelProgress!: number;

  @ApiProperty({ description: 'XP accumulated inside the current level' })
  pointsInLevel!: number;

  @ApiProperty({ description: 'XP remaining until the next level' })
  pointsToNextLevel!: number;

  @ApiProperty({
    description:
      'Stable tier id for icons and localization (e.g. numeric_5, prestige_03, prestige_cap)',
  })
  levelTierKey!: string;

  @ApiProperty({ description: 'English tier title; clients may localize via levelTierKey' })
  levelDisplayName!: string;

  @ApiProperty({
    description:
      'Sum of positive point credits for this user in the current Skopje week (all sources)',
  })
  weeklyPoints!: number;

  @ApiProperty({ nullable: true, description: '1-based rank among citizens with weeklyPoints > 0' })
  weeklyRank!: number | null;

  @ApiProperty({ description: 'Current week start (Monday Skopje), ISO-8601' })
  weekStartsAt!: string;

  @ApiProperty({ description: 'Current week end (Sunday Skopje), ISO-8601' })
  weekEndsAt!: string;
}
