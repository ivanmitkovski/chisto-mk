import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { AuditModule } from '../audit/audit.module';
import { SessionsModule } from '../sessions/sessions.module';
import { SitesModule } from '../sites/sites.module';
import { AdminAggregationQueryService } from './admin-aggregation-query.service';
import { AdminController } from './admin.controller';
import { AdminDashboardStatsService } from './admin-dashboard-stats.service';
import { AdminService } from './admin.service';

@Module({
  imports: [PrismaModule, AuditModule, SessionsModule, SitesModule],
  controllers: [AdminController],
  providers: [AdminService, AdminDashboardStatsService, AdminAggregationQueryService],
})
export class AdminModule {}

