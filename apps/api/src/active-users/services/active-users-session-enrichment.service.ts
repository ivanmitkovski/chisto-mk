import { Injectable } from '@nestjs/common';
import { DevicePlatform } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { GeoIpService } from './geo-ip.service';
import { ActiveUsersPresenceService } from './active-users-presence.service';

@Injectable()
export class ActiveUsersSessionEnrichmentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly geoIp: GeoIpService,
    private readonly presence: ActiveUsersPresenceService,
  ) {}

  async onLogin(opts: {
    userId: string;
    sessionId: string;
    deviceId?: string | null;
    ipAddress?: string | null;
    deviceInfo?: string | null;
  }): Promise<void> {
    const geo = await this.geoIp.lookup(opts.ipAddress);
    await Promise.all([
      this.prisma.user.update({
        where: { id: opts.userId },
        data: { lastActiveAt: new Date() },
      }),
      this.prisma.userSession.update({
        where: { id: opts.sessionId },
        data: {
          lastSeenAt: new Date(),
          ...(opts.ipAddress?.trim() ? { ipAddress: opts.ipAddress.trim() } : {}),
          ...(opts.deviceInfo?.trim() ? { deviceInfo: opts.deviceInfo.trim() } : {}),
          ...(opts.deviceId?.trim() ? { deviceId: opts.deviceId.trim() } : {}),
          country: geo.country,
          city: geo.city,
        },
      }),
    ]);
    if (opts.deviceId) {
      void this.presence.applySessionGeo(opts.sessionId, geo.country, geo.city);
      void this.presence.enrichMetaFromSession(opts.userId, opts.deviceId, opts.sessionId);
    }
  }

  async touchSession(
    sessionId: string,
    userId: string,
    meta: {
      platform?: DevicePlatform;
      appVersion?: string | null;
      deviceModel?: string | null;
      osVersion?: string | null;
    },
  ): Promise<void> {
    await this.prisma.userSession.updateMany({
      where: { id: sessionId, userId },
      data: {
        lastSeenAt: new Date(),
        ...(meta.platform ? { platform: meta.platform } : {}),
        ...(meta.appVersion != null ? { appVersion: meta.appVersion } : {}),
        ...(meta.deviceModel != null ? { deviceModel: meta.deviceModel } : {}),
        ...(meta.osVersion != null ? { osVersion: meta.osVersion } : {}),
      },
    });
  }
}
