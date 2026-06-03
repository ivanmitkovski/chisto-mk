import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class UserDsarExportService {
  constructor(private readonly prisma: PrismaService) {}

  async buildExport(userId: string): Promise<Record<string, unknown>> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        createdAt: true,
        firstName: true,
        lastName: true,
        email: true,
        phoneNumber: true,
        role: true,
        status: true,
        isPhoneVerified: true,
        pointsBalance: true,
        homeLatitude: true,
        homeLongitude: true,
        homeLocationLabel: true,
        termsAcceptedAt: true,
        termsVersion: true,
        privacyAcceptedAt: true,
      },
    });

    const [reports, comments, notifications, preferences, sessions, pointHistory] =
      await Promise.all([
        this.prisma.report.findMany({
          where: { reporterId: userId },
          select: {
            id: true,
            title: true,
            description: true,
            status: true,
            createdAt: true,
            siteId: true,
          },
          take: 500,
          orderBy: { createdAt: 'desc' },
        }),
        this.prisma.siteComment.findMany({
          where: { authorId: userId },
          select: { id: true, siteId: true, body: true, createdAt: true, isDeleted: true },
          take: 500,
          orderBy: { createdAt: 'desc' },
        }),
        this.prisma.userNotification.findMany({
          where: { userId },
          select: { id: true, type: true, title: true, body: true, createdAt: true, isRead: true },
          take: 200,
          orderBy: { createdAt: 'desc' },
        }),
        this.prisma.userNotificationPreference.findMany({
          where: { userId },
          select: { type: true, muted: true, emailMuted: true, updatedAt: true },
        }),
        this.prisma.userSession.findMany({
          where: { userId },
          select: {
            id: true,
            createdAt: true,
            expiresAt: true,
            revokedAt: true,
            deviceInfo: true,
          },
          take: 50,
          orderBy: { createdAt: 'desc' },
        }),
        this.prisma.pointTransaction.findMany({
          where: { userId },
          select: { id: true, delta: true, reasonCode: true, createdAt: true },
          take: 200,
          orderBy: { createdAt: 'desc' },
        }),
      ]);

    return {
      exportedAt: new Date().toISOString(),
      format: 'chisto-dsar-v1',
      profile: user,
      reports,
      siteComments: comments,
      notifications,
      notificationPreferences: preferences,
      sessions: sessions.map((s) => ({
        ...s,
        note: 'Refresh token hashes are never exported',
      })),
      pointTransactions: pointHistory,
    };
  }

  /** NDJSON stream: one JSON object per line per section. */
  async *streamSections(userId: string): AsyncGenerator<string> {
    const full = await this.buildExport(userId);
    const sections: Array<[string, unknown]> = [
      ['meta', { exportedAt: full.exportedAt, format: full.format }],
      ['profile', full.profile],
      ['reports', full.reports],
      ['siteComments', full.siteComments],
      ['notifications', full.notifications],
      ['notificationPreferences', full.notificationPreferences],
      ['sessions', full.sessions],
      ['pointTransactions', full.pointTransactions],
    ];
    for (const [section, data] of sections) {
      yield `${JSON.stringify({ section, data })}\n`;
    }
  }
}
