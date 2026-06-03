import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { AuditModule } from '../audit/audit.module';
import { SessionsModule } from '../sessions/sessions.module';
import { SitesModule } from '../sites/sites.module';
import { AdminAggregationQueryService } from './services/admin-aggregation-query.service';
import { AdminController } from './controllers/admin.controller';
import { AdminDashboardStatsService } from './services/admin-dashboard-stats.service';
import { AdminService } from './services/admin.service';

@Module({
  imports: [PrismaModule, AuditModule, SessionsModule, SitesModule],
  controllers: [AdminController],
  providers: [AdminService, AdminDashboardStatsService, AdminAggregationQueryService],
})
export class AdminModule {}

