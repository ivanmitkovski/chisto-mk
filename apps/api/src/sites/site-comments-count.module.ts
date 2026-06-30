import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { ModerationModule } from '../moderation/moderation.module';
import { SiteCommentsCountService } from './services/site-comments-count.service';

@Module({
  imports: [PrismaModule, ModerationModule],
  providers: [SiteCommentsCountService],
  exports: [SiteCommentsCountService],
})
export class SiteCommentsCountModule {}
