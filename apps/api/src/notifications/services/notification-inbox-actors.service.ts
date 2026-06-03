import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ReportsUploadService } from '../../reports/services/reports-upload.service';
import { NotificationActorDto } from '../dto/notification-actor.dto';
import { extractActorUserId } from '../util/notification-inbox.mapper';

@Injectable()
export class NotificationInboxActorsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUpload: ReportsUploadService,
  ) {}

  async resolveActorsForNotifications(
    notifications: Array<{ data: unknown }>,
  ): Promise<Map<string, NotificationActorDto>> {
    const actorIds = [
      ...new Set(
        notifications
          .map((n) => extractActorUserId(n.data))
          .filter((id): id is string => id != null),
      ),
    ];
    if (actorIds.length === 0) return new Map();

    const users = await this.prisma.user.findMany({
      where: { id: { in: actorIds } },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        avatarObjectKey: true,
      },
    });

    const avatarUrlByKey = new Map<string, string | null>();
    const signingTasks = new Map<string, Promise<string | null>>();
    for (const user of users) {
      const key = user.avatarObjectKey?.trim();
      if (!key) continue;
      if (!signingTasks.has(key)) {
        signingTasks.set(key, this.reportsUpload.signPrivateObjectKey(key));
      }
    }
    await Promise.all(
      [...signingTasks.entries()].map(async ([key, task]) => {
        avatarUrlByKey.set(key, await task);
      }),
    );

    const result = new Map<string, NotificationActorDto>();
    for (const user of users) {
      const displayName = `${user.firstName} ${user.lastName}`.trim() || user.id;
      const key = user.avatarObjectKey?.trim();
      const avatarUrl =
        key != null && key.length > 0 ? (avatarUrlByKey.get(key) ?? null) : null;
      result.set(user.id, {
        id: user.id,
        displayName,
        avatarUrl,
      });
    }
    return result;
  }
}
