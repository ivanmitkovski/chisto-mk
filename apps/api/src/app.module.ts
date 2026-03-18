import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { ReportsModule } from './reports/reports.module';
import { SitesModule } from './sites/sites.module';
import { AuthModule } from './auth/auth.module';
import { AdminModule } from './admin/admin.module';
import { AdminNotificationsModule } from './admin-notifications/admin-notifications.module';
import { HealthModule } from './health/health.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    HealthModule,
    ThrottlerModule.forRoot([{
      ttl: 60_000,
      limit: 60,
    }]),
    PrismaModule,
    AuthModule,
    SitesModule,
    ReportsModule,
    AdminModule,
    AdminNotificationsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
