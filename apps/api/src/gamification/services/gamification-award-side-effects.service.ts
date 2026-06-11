import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { NotificationType } from '../../prisma-client';
import { notificationLocalesByUserId } from '../../common/i18n/notification-locale.resolver';
import { achievementLevelUpCopy } from '../../notifications/util/notification-templates';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationDispatcherService } from '../../notifications/services/notification-dispatcher.service';
import { GamificationService } from './gamification.service';
import type { EcoEventPointsCreditResult } from './eco-event-points.service';

export type GamificationPointsCreditedEvent = {
  userId: string;
  credit: EcoEventPointsCreditResult;
};

@Injectable()
export class GamificationAwardSideEffectsService {
  private readonly logger = new Logger(GamificationAwardSideEffectsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly gamification: GamificationService,
    private readonly dispatcher: NotificationDispatcherService,
  ) {}

  @OnEvent('gamification.points.credited')
  async handlePointsCredited(event: GamificationPointsCreditedEvent): Promise<void> {
    await this.notifyLevelUpAfterCredit(event.userId, event.credit);
  }

  async notifyLevelUpAfterCredit(
    userId: string,
    credit: EcoEventPointsCreditResult,
  ): Promise<void> {
    if (credit.granted <= 0) {
      return;
    }
    const before = this.gamification.getLevelProgress(credit.totalPointsEarnedBefore);
    const afterLevel = this.gamification.getLevelProgress(credit.totalPointsEarnedAfter);
    if (afterLevel.level <= before.level) {
      return;
    }

    try {
      const localeBy = await notificationLocalesByUserId(this.prisma, [userId]);
      const locale = localeBy.get(userId)!;
      const after = this.gamification.getLevelProgress(credit.totalPointsEarnedAfter, locale);
      const { title, body } = achievementLevelUpCopy(locale, after.levelDisplayName);
      await this.dispatcher.dispatchToUser(userId, {
        title,
        body,
        type: NotificationType.ACHIEVEMENT,
        data: {
          kind: 'level_up',
          level: String(after.level),
          levelTierKey: after.levelTierKey,
          pointsAwarded: String(credit.granted),
        },
        threadKey: `achievement:level_up:${userId}:${after.level}`,
        groupKey: `ACHIEVEMENT:level_up`,
      });
    } catch (err: unknown) {
      this.logger.warn({
        msg: 'achievement_level_up_notification_failed',
        userId,
        error: String(err),
      });
    }
  }
}
