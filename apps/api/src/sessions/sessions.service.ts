import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { AuditService } from '../audit/audit.service';

export type AdminSessionRow = {
  id: string;
  device: string;
  location: string;
  ipAddress: string;
  lastActiveLabel: string;
  isCurrent: boolean;
};

@Injectable()
export class SessionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async listMine(admin: AuthenticatedUser): Promise<AdminSessionRow[]> {
    const now = new Date();
    const sessions = await this.prisma.userSession.findMany({
      where: {
        userId: admin.userId,
        revokedAt: null,
        expiresAt: { gt: now },
      },
      orderBy: { createdAt: 'desc' },
    });

    return sessions.map((s) => ({
      id: s.id,
      device: s.deviceInfo?.trim() || 'Browser session',
      location: '—',
      ipAddress: s.ipAddress?.trim() || '—',
      lastActiveLabel: s.createdAt.toISOString(),
      isCurrent: admin.sessionId != null && s.id === admin.sessionId,
    }));
  }

  async revokeOthers(admin: AuthenticatedUser): Promise<{ revoked: number }> {
    if (!admin.sessionId) {
      throw new BadRequestException({
        code: 'SESSION_CONTEXT_REQUIRED',
        message: 'Sign in again to manage sessions',
      });
    }

    const now = new Date();
    const result = await this.prisma.userSession.updateMany({
      where: {
        userId: admin.userId,
        id: { not: admin.sessionId },
        revokedAt: null,
      },
      data: { revokedAt: now },
    });

    await this.audit.log({
      actorId: admin.userId,
      action: 'SESSION_REVOKE_OTHERS',
      resourceType: 'UserSession',
      resourceId: admin.sessionId,
      metadata: { count: result.count },
    });

    return { revoked: result.count };
  }
}
