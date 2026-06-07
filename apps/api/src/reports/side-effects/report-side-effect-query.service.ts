import { Injectable } from '@nestjs/common';
import { ReportSideEffectStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ReportSideEffectQueryService {
  constructor(private readonly prisma: PrismaService) {}

  async countPending(): Promise<number> {
    return this.prisma.reportSideEffect.count({
      where: { status: ReportSideEffectStatus.PENDING },
    });
  }
}
