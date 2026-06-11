import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { EcoEventPointsService } from './services/eco-event-points.service';
import { GamificationService } from './services/gamification.service';
import { GamificationAwardSideEffectsService } from './services/gamification-award-side-effects.service';
import { PointHistoryService } from './services/point-history.service';
import { RankingsController } from './controllers/rankings.controller';
import { RankingsService } from './services/rankings.service';

@Module({
  imports: [PrismaModule, ReportsUploadModule, NotificationsModule],
  controllers: [RankingsController],
  providers: [
    GamificationService,
    RankingsService,
    PointHistoryService,
    EcoEventPointsService,
    GamificationAwardSideEffectsService,
  ],
  exports: [
    GamificationService,
    RankingsService,
    PointHistoryService,
    EcoEventPointsService,
    GamificationAwardSideEffectsService,
  ],
})
export class GamificationModule {}
