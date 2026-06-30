import { Injectable } from '@nestjs/common';
import { UserStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AdminUsersStatusHistoryService {
  constructor(private readonly prisma: PrismaService) {}

  async recordStatusAction(input: {
    userId: string;
    actorId: string;
    fromStatus: UserStatus;
    toStatus: UserStatus;
    reasonCode: string;
    note: string | null;
  }): Promise<void> {
    await this.prisma.userStatusAction.create({
      data: {
        userId: input.userId,
        actorId: input.actorId,
        fromStatus: input.fromStatus,
        toStatus: input.toStatus,
        reasonCode: input.reasonCode,
        note: input.note,
      },
    });
  }
}
