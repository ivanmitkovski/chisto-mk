import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Role, UserStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { GamificationService } from '../gamification/gamification.service';
import { RankingsService } from '../gamification/rankings.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { AuthenticatedUser } from './types/authenticated-user.type';

@Injectable()
export class AuthProfileService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly gamificationService: GamificationService,
    private readonly rankingsService: RankingsService,
  ) {}

  async me(authenticatedUser: AuthenticatedUser, locale = 'en'): Promise<{
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    phoneNumber: string;
    role: Role;
    status: UserStatus;
    isPhoneVerified: boolean;
    pointsBalance: number;
    totalPointsEarned: number;
    totalPointsSpent: number;
    mfaEnabled: boolean;
    avatarUrl: string | null;
    level: number;
    levelProgress: number;
    pointsInLevel: number;
    pointsToNextLevel: number;
    levelTierKey: string;
    levelDisplayName: string;
    weeklyPoints: number;
    weeklyRank: number | null;
    weekStartsAt: string;
    weekEndsAt: string;
    organizerCertifiedAt: string | null;
  }> {
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
      },
    });

    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User for token was not found',
      });
    }

    const avatarUrl = await this.reportsUploadService.signPrivateObjectKey(user.avatarObjectKey);
    const { totpSecret, avatarObjectKey, organizerCertifiedAt, ...rest } = user;
    void totpSecret;
    void avatarObjectKey;
    const levelState = this.gamificationService.getLevelProgress(user.totalPointsEarned, locale);
    const weekly = await this.rankingsService.getUserWeeklySummary(authenticatedUser.userId);
    return {
      ...rest,
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
    };
  }

  async updateProfile(
    userId: string,
    dto: UpdateProfileDto,
  ): Promise<{
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    phoneNumber: string;
    avatarUrl: string | null;
  }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, status: true },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }
    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        code: 'ACCOUNT_NOT_ACTIVE',
        message: 'Account is not active',
      });
    }
    const data: { firstName?: string; lastName?: string } = {};
    if (dto.firstName != null && dto.firstName.trim().length > 0) {
      data.firstName = dto.firstName.trim();
    }
    if (dto.lastName != null && dto.lastName.trim().length > 0) {
      data.lastName = dto.lastName.trim();
    }
    if (Object.keys(data).length === 0) {
      const updated = await this.prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          firstName: true,
          lastName: true,
          email: true,
          phoneNumber: true,
          avatarObjectKey: true,
        },
      });
      if (!updated) {
        throw new UnauthorizedException({ code: 'INVALID_TOKEN_USER', message: 'User not found' });
      }
      return {
        id: updated.id,
        firstName: updated.firstName,
        lastName: updated.lastName,
        email: updated.email,
        phoneNumber: updated.phoneNumber,
        avatarUrl: await this.reportsUploadService.signPrivateObjectKey(updated.avatarObjectKey),
      };
    }
    const updated = await this.prisma.user.update({
      where: { id: userId },
      data,
      select: {
        id: true,
        firstName: true,
        lastName: true,
        email: true,
        phoneNumber: true,
        avatarObjectKey: true,
      },
    });
    return {
      id: updated.id,
      firstName: updated.firstName,
      lastName: updated.lastName,
      email: updated.email,
      phoneNumber: updated.phoneNumber,
      avatarUrl: await this.reportsUploadService.signPrivateObjectKey(updated.avatarObjectKey),
    };
  }

  async uploadAvatar(
    userId: string,
    file: Express.Multer.File | undefined,
  ): Promise<{ avatarUrl: string | null }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, status: true, avatarObjectKey: true },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }
    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        code: 'ACCOUNT_NOT_ACTIVE',
        message: 'Account is not active',
      });
    }
    if (!file) {
      throw new BadRequestException({
        code: 'AVATAR_FILE_REQUIRED',
        message: 'Avatar image file is required.',
      });
    }
    const nextKey = await this.reportsUploadService.uploadProfileAvatar(userId, file);
    await this.prisma.user.update({
      where: { id: userId },
      data: { avatarObjectKey: nextKey, avatarUpdatedAt: new Date() },
    });
    const signedUrl = await this.reportsUploadService.signPrivateObjectKey(nextKey);
    if (user.avatarObjectKey) {
      void this.reportsUploadService.deleteObjectByKey(user.avatarObjectKey).catch(() => {});
    }
    return { avatarUrl: signedUrl };
  }

  async removeAvatar(userId: string): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, status: true, avatarObjectKey: true },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }
    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        code: 'ACCOUNT_NOT_ACTIVE',
        message: 'Account is not active',
      });
    }
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        avatarObjectKey: null,
        avatarUpdatedAt: new Date(),
      },
    });
    if (user.avatarObjectKey) {
      void this.reportsUploadService.deleteObjectByKey(user.avatarObjectKey).catch(() => {});
    }
  }

  async deleteAccount(userId: string): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }
    const now = new Date();
    await this.prisma.$transaction([
      this.prisma.userSession.updateMany({
        where: { userId: user.id },
        data: { revokedAt: now },
      }),
      this.prisma.user.update({
        where: { id: userId },
        data: { status: UserStatus.DELETED },
      }),
    ]);
  }
}
