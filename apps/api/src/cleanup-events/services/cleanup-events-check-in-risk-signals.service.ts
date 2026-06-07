import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../../prisma-client';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { CheckInRiskSignalRealtimeService } from '../../admin-realtime/services/check-in-risk-signal-realtime.service';
import { PrismaService } from '../../prisma/prisma.service';
import { ListCheckInRiskSignalsQueryDto } from '../dto/list-check-in-risk-signals-query.dto';
import { PatchCheckInRiskSignalDto } from '../dto/patch-check-in-risk-signal.dto';

type RiskSignalRow = {
  id: string;
  createdAt: Date;
  expiresAt: Date;
  eventId: string;
  userId: string;
  signalType: string;
  metadata: unknown;
  resolvedAt: Date | null;
  resolvedByUserId: string | null;
  resolutionAction: string | null;
  event: { title: string };
  user: { firstName: string; lastName: string };
};

@Injectable()
export class CleanupEventsCheckInRiskSignalsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly checkInRiskSignalRealtime: CheckInRiskSignalRealtimeService,
  ) {}

  async listCheckInRiskSignals(query: ListCheckInRiskSignalsQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 50;
    const skip = (page - 1) * limit;
    const status = query.status ?? 'active';
    const now = new Date();
    const where = this.buildListWhere(status, now, query.eventId?.trim());

    const [rows, total] = await Promise.all([
      this.prisma.checkInRiskSignal.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        select: {
          id: true,
          createdAt: true,
          expiresAt: true,
          eventId: true,
          userId: true,
          signalType: true,
          metadata: true,
          resolvedAt: true,
          resolvedByUserId: true,
          resolutionAction: true,
          event: { select: { title: true } },
          user: { select: { firstName: true, lastName: true } },
        },
      }),
      this.prisma.checkInRiskSignal.count({ where }),
    ]);

    return {
      data: rows.map((r) => this.toListItem(r)),
      page,
      limit,
      total,
    };
  }

  async patchCheckInRiskSignal(
    id: string,
    dto: PatchCheckInRiskSignalDto,
    actor: AuthenticatedUser,
  ) {
    const existing = await this.prisma.checkInRiskSignal.findUnique({
      where: { id },
      select: {
        id: true,
        resolvedAt: true,
      },
    });
    if (!existing) {
      throw new NotFoundException({
        code: 'CHECK_IN_RISK_SIGNAL_NOT_FOUND',
        message: 'Check-in risk signal not found',
      });
    }
    if (existing.resolvedAt) {
      throw new BadRequestException({
        code: 'CHECK_IN_RISK_SIGNAL_ALREADY_RESOLVED',
        message: 'Check-in risk signal is already resolved',
      });
    }

    const updated = await this.prisma.checkInRiskSignal.update({
      where: { id },
      data: {
        resolvedAt: new Date(),
        resolvedByUserId: actor.userId,
        resolutionAction: dto.action,
      },
      select: {
        id: true,
        createdAt: true,
        expiresAt: true,
        eventId: true,
        userId: true,
        signalType: true,
        metadata: true,
        resolvedAt: true,
        resolvedByUserId: true,
        resolutionAction: true,
        event: { select: { title: true } },
        user: { select: { firstName: true, lastName: true } },
      },
    });

    this.checkInRiskSignalRealtime.emitUpdated(updated.id, updated.eventId);

    return {
      ...this.toListItem(updated),
      action: dto.action,
    };
  }

  private buildListWhere(
    status: NonNullable<ListCheckInRiskSignalsQueryDto['status']> | 'active',
    now: Date,
    eventId?: string,
  ): Prisma.CheckInRiskSignalWhereInput {
    const base: Prisma.CheckInRiskSignalWhereInput =
      status === 'resolved'
        ? { resolvedAt: { not: null } }
        : status === 'all'
          ? {}
          : {
              resolvedAt: null,
              expiresAt: { gt: now },
            };
    if (eventId != null && eventId.length > 0) {
      return { ...base, eventId };
    }
    return base;
  }

  private toListItem(r: RiskSignalRow) {
    return {
      id: r.id,
      createdAt: r.createdAt.toISOString(),
      expiresAt: r.expiresAt.toISOString(),
      eventId: r.eventId,
      eventTitle: r.event.title,
      userId: r.userId,
      userDisplayName: `${r.user.firstName} ${r.user.lastName}`.trim(),
      signalType: r.signalType,
      metadata: r.metadata,
      resolvedAt: r.resolvedAt?.toISOString() ?? null,
      resolvedByUserId: r.resolvedByUserId,
      resolutionAction: r.resolutionAction,
    };
  }
}
