import { Injectable, UnauthorizedException } from '@nestjs/common';
import { UserStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UpdateHomeLocationDto } from './dto/update-home-location.dto';
import { assertHomeLocationInMacedonia } from './auth-home-location.util';
import { AuthenticatedUser } from './types/authenticated-user.type';
import { AuthProfileReadService } from './auth-profile-read.service';
import { AuthProfileAvatarService } from './auth-profile-avatar.service';

@Injectable()
export class AuthProfileService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly readService: AuthProfileReadService,
    private readonly avatarService: AuthProfileAvatarService,
  ) {}

  me(authenticatedUser: AuthenticatedUser, locale = 'en') {
    return this.readService.me(authenticatedUser, locale);
  }

  uploadAvatar(userId: string, file: Express.Multer.File | undefined) {
    return this.avatarService.uploadAvatar(userId, file);
  }

  removeAvatar(userId: string) {
    return this.avatarService.removeAvatar(userId);
  }

  async updateHomeLocation(userId: string, dto: UpdateHomeLocationDto) {
    assertHomeLocationInMacedonia(dto.latitude, dto.longitude);
    await this.assertActiveUser(userId);
    const label = dto.label?.trim() || null;
    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        homeLatitude: dto.latitude,
        homeLongitude: dto.longitude,
        homeLocationLabel: label,
        homeLocationSetAt: new Date(),
      },
      select: {
        homeLatitude: true,
        homeLongitude: true,
        homeLocationLabel: true,
        homeLocationSetAt: true,
      },
    });
    return {
      homeLatitude: updated.homeLatitude!,
      homeLongitude: updated.homeLongitude!,
      homeLocationLabel: updated.homeLocationLabel,
      homeLocationSetAt: updated.homeLocationSetAt!.toISOString(),
    };
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    await this.assertActiveUser(userId);
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
      return this.profileResponse(updated);
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
    return this.profileResponse(updated);
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

  private async profileResponse(updated: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    phoneNumber: string;
    avatarObjectKey: string | null;
  }) {
    return {
      id: updated.id,
      firstName: updated.firstName,
      lastName: updated.lastName,
      email: updated.email,
      phoneNumber: updated.phoneNumber,
      avatarUrl: await this.reportsUploadService.signPrivateObjectKey(updated.avatarObjectKey),
    };
  }

  private async assertActiveUser(userId: string): Promise<void> {
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
  }
}
