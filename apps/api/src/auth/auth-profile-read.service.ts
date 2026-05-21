import { Injectable, UnauthorizedException } from '@nestjs/common';
import { Role, UserStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { GamificationService } from '../gamification/gamification.service';
import { RankingsService } from '../gamification/rankings.service';
import { AuthenticatedUser } from './types/authenticated-user.type';
import { ConfigService } from '@nestjs/config';
import { resolveTermsVersionFromEnv, termsConsentPayload } from './terms-consent.util';

@Injectable()
export class AuthProfileReadService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly gamificationService: GamificationService,
    private readonly rankingsService: RankingsService,
    private readonly configService: ConfigService,
  ) {}

  async me(authenticatedUser: AuthenticatedUser, locale = 'en') {
    const user = await this.prisma.user.findUnique({
      where: { id: authenticatedUser.userId },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        email: true,
        phoneNumber: true,
        role: true,
        status: true,
        isPhoneVerified: true,
        pointsBalance: true,
        totalPointsEarned: true,
        totalPointsSpent: true,
        totpSecret: true,
        avatarObjectKey: true,
        organizerCertifiedAt: true,
        homeLatitude: true,
        homeLongitude: true,
        homeLocationLabel: true,
        homeLocationSetAt: true,
        termsAcceptedAt: true,
        termsVersion: true,
      },
    });

    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User for token was not found',
      });
    }

    const avatarUrl = await this.reportsUploadService.signPrivateObjectKey(user.avatarObjectKey);
    const {
      totpSecret,
      avatarObjectKey,
      organizerCertifiedAt,
      homeLocationSetAt,
      ...rest
    } = user;
    void totpSecret;
    void avatarObjectKey;
    const levelState = this.gamificationService.getLevelProgress(user.totalPointsEarned, locale);
    const weekly = await this.rankingsService.getUserWeeklySummary(authenticatedUser.userId);
    const currentTermsVersion = resolveTermsVersionFromEnv(
      this.configService.get<string>('TERMS_VERSION'),
    );
    const consent = termsConsentPayload(user, currentTermsVersion);
    return {
      ...rest,
      role: rest.role as Role,
      status: rest.status as UserStatus,
      mfaEnabled: !!user.totpSecret,
      avatarUrl,
      level: levelState.level,
      levelProgress: levelState.levelProgress,
      pointsInLevel: levelState.pointsInLevel,
      pointsToNextLevel: levelState.pointsToNextLevel,
      levelTierKey: levelState.levelTierKey,
      levelDisplayName: levelState.levelDisplayName,
      weeklyPoints: weekly.weeklyPoints,
      weeklyRank: weekly.weeklyRank,
      weekStartsAt: weekly.weekStartsAt,
      weekEndsAt: weekly.weekEndsAt,
      organizerCertifiedAt: organizerCertifiedAt?.toISOString() ?? null,
      homeLocationSetAt: homeLocationSetAt?.toISOString() ?? null,
      ...consent,
    };
  }
}
