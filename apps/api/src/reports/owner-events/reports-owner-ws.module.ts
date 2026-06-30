import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../../prisma/prisma.module';
import { OwnerEventsModule } from './owner-events.module';
import { ReportsOwnerGateway } from './reports-owner.gateway';

@Module({
  imports: [ConfigModule, PrismaModule, OwnerEventsModule],
  providers: [ReportsOwnerGateway],
})
export class ReportsOwnerWsModule {}
