import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PRESENCE_CONFIG } from '../config/presence.config';
import { UserActivityService } from './user-activity.service';

@Injectable()
export class ActivityRetentionCronService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ActivityRetentionCronService.name);
  private timer: ReturnType<typeof setInterval> | null = null;

  constructor(private readonly activity: UserActivityService) {}

  onModuleInit(): void {
    if (process.env.ACTIVITY_RETENTION_CRON_ENABLED === 'false') return;
    this.timer = setInterval(() => void this.purge(), 24 * 60 * 60_000);
    void this.purge();
  }

  onModuleDestroy(): void {
    if (this.timer) clearInterval(this.timer);
  }

  private async purge(): Promise<void> {
    try {
      const deleted = await this.activity.purgeOldEvents(PRESENCE_CONFIG.activityRetentionDays);
      if (deleted > 0) {
        this.logger.log(`Purged ${deleted} activity events older than ${PRESENCE_CONFIG.activityRetentionDays} days`);
      }
    } catch (error) {
      this.logger.warn(`activity retention purge failed: ${String(error)}`);
    }
  }
}
