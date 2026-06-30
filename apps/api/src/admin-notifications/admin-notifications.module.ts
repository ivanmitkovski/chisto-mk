import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { AdminNotificationsController } from './controllers/admin-notifications.controller';
import { AdminNotificationsService } from './services/admin-notifications.service';

@Module({
  imports: [PrismaModule],
  controllers: [AdminNotificationsController],
  providers: [AdminNotificationsService],
})
export class AdminNotificationsModule {}

