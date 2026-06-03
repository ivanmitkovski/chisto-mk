import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { EcoEventPointsService } from './services/eco-event-points.service';
import { GamificationService } from './services/gamification.service';
import { PointHistoryService } from './services/point-history.service';
import { RankingsController } from './controllers/rankings.controller';
import { RankingsService } from './services/rankings.service';

@Module({
  imports: [PrismaModule],
  controllers: [RankingsController],
  providers: [GamificationService, RankingsService, PointHistoryService, EcoEventPointsService],
  exports: [GamificationService, RankingsService, PointHistoryService, EcoEventPointsService],
})
export class GamificationModule {}
