import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { GamificationService } from './gamification.service';
import { PointHistoryService } from './point-history.service';
import { RankingsController } from './rankings.controller';
import { RankingsService } from './rankings.service';

@Module({
  imports: [PrismaModule],
  controllers: [RankingsController],
  providers: [GamificationService, RankingsService, PointHistoryService],
  exports: [GamificationService, RankingsService, PointHistoryService],
})
export class GamificationModule {}
