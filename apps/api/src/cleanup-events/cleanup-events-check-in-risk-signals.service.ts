import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ListCheckInRiskSignalsQueryDto } from './dto/list-check-in-risk-signals-query.dto';

@Injectable()
export class CleanupEventsCheckInRiskSignalsService {
  constructor(private readonly prisma: PrismaService) {}

  async listCheckInRiskSignals(query: ListCheckInRiskSignalsQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 50;
    const skip = (page - 1) * limit;
    const now = new Date();
    const where = { expiresAt: { gt: now } };
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
          event: { select: { title: true } },
          user: { select: { firstName: true, lastName: true } },
        },
      }),
      this.prisma.checkInRiskSignal.count({ where }),
    ]);
    return {
      data: rows.map((r) => ({
        id: r.id,
        createdAt: r.createdAt.toISOString(),
        expiresAt: r.expiresAt.toISOString(),
        eventId: r.eventId,
        eventTitle: r.event.title,
        userId: r.userId,
        userDisplayName: `${r.user.firstName} ${r.user.lastName}`.trim(),
        signalType: r.signalType,
        metadata: r.metadata,
      })),
      page,
      limit,
      total,
    };
  }
}
