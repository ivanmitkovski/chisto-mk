import { ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';

@Injectable()
export class DeviceTokenService {
  constructor(private readonly prisma: PrismaService) {}

  async registerDeviceToken(
    user: AuthenticatedUser,
    dto: RegisterDeviceTokenDto,
  ): Promise<{ id: string }> {
    const existing = await this.prisma.userDeviceToken.findUnique({
      where: { token: dto.token },
      select: { id: true, userId: true, revokedAt: true },
    });

    if (existing) {
      if (existing.userId !== user.userId && existing.revokedAt == null) {
        throw new ForbiddenException({
          code: 'DEVICE_TOKEN_IN_USE',
          message: 'This device is already registered to another account',
        });
      }
      const updated = await this.prisma.userDeviceToken.update({
        where: { id: existing.id },
        data: {
          userId: user.userId,
          platform: dto.platform,
          appVersion: dto.appVersion ?? null,
          locale: dto.locale ?? null,
          lastSeenAt: new Date(),
          revokedAt: null,
          failureCount: 0,
        },
        select: { id: true },
      });
      return { id: updated.id };
    }

    const created = await this.prisma.userDeviceToken.create({
      data: {
        userId: user.userId,
        token: dto.token,
        platform: dto.platform,
        appVersion: dto.appVersion ?? null,
        locale: dto.locale ?? null,
      },
      select: { id: true },
    });
    return { id: created.id };
  }

  async unregisterDeviceToken(
    user: AuthenticatedUser,
    token: string,
  ): Promise<void> {
    const existing = await this.prisma.userDeviceToken.findUnique({
      where: { token },
      select: { id: true, userId: true },
    });

    if (!existing || existing.userId !== user.userId) return;

    await this.prisma.userDeviceToken.update({
      where: { id: existing.id },
      data: { revokedAt: new Date() },
    });
  }

  async getActiveTokensForUser(userId: string) {
    return this.prisma.userDeviceToken.findMany({
      where: { userId, revokedAt: null },
      select: { id: true, token: true, platform: true },
    });
  }
}
