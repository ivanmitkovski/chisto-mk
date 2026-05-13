import { Injectable } from '@nestjs/common';
import { NotificationType } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { UpdateNotificationPreferenceDto } from './dto/update-notification-preference.dto';

type NotificationPreferenceItem = {
  type: NotificationType;
  muted: boolean;
  mutedUntil: string | null;
};

@Injectable()
export class NotificationPreferencesService {
  constructor(private readonly prisma: PrismaService) {}

  async listPreferences(
    user: AuthenticatedUser,
  ): Promise<{ data: NotificationPreferenceItem[] }> {
    const rows = await this.prisma.userNotificationPreference.findMany({
      where: { userId: user.userId },
      select: { type: true, muted: true, mutedUntil: true },
    });
    const byType = new Map<NotificationType, { muted: boolean; mutedUntil: Date | null }>();
    for (const row of rows) {
      byType.set(row.type, { muted: row.muted, mutedUntil: row.mutedUntil });
    }
    const data = Object.values(NotificationType).map((type) => {
      const pref = byType.get(type);
      return {
        type,
        muted: pref?.muted ?? false,
        mutedUntil: pref?.mutedUntil?.toISOString() ?? null,
      };
    });
    return { data };
  }

  async updatePreference(
    user: AuthenticatedUser,
    type: NotificationType,
    dto: UpdateNotificationPreferenceDto,
  ): Promise<NotificationPreferenceItem> {
    const parsedMutedUntil =
      dto.mutedUntil != null && dto.mutedUntil.trim() !== ''
        ? new Date(dto.mutedUntil)
        : null;
    const mutedUntil = dto.muted && parsedMutedUntil && !Number.isNaN(parsedMutedUntil.getTime())
      ? parsedMutedUntil
      : null;
    const row = await this.prisma.userNotificationPreference.upsert({
      where: {
        userId_type: { userId: user.userId, type },
      },
      create: {
        userId: user.userId,
        type,
        muted: dto.muted,
        mutedUntil,
      },
      update: {
        muted: dto.muted,
        mutedUntil,
      },
      select: {
        type: true,
        muted: true,
        mutedUntil: true,
      },
    });
    return {
      type: row.type,
      muted: row.muted,
      mutedUntil: row.mutedUntil?.toISOString() ?? null,
    };
  }

  async isTypeMuted(
    userId: string,
    type: NotificationType,
  ): Promise<boolean> {
    const pref = await this.prisma.userNotificationPreference.findUnique({
      where: { userId_type: { userId, type } },
      select: { muted: true, mutedUntil: true },
    });
    if (!pref?.muted) return false;
    if (pref.mutedUntil == null) return true;
    if (pref.mutedUntil.getTime() > Date.now()) return true;
    await this.prisma.userNotificationPreference.update({
      where: { userId_type: { userId, type } },
      data: { muted: false, mutedUntil: null },
    });
    return false;
  }
}
