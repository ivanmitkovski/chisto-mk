import { Module } from '@nestjs/common';
import { AdminRealtimeModule } from '../../../admin-realtime/admin-realtime.module';
import { PrismaModule } from '../../../prisma/prisma.module';
import { TypesenseClientService } from './typesense-client.service';
import { TypesenseSitesIndexService } from './typesense-sites-index.service';
import { TypesenseSitesSearchService } from './typesense-sites-search.service';
import { TypesenseSitesSyncService } from './typesense-sites-sync.service';

@Module({
  imports: [PrismaModule, AdminRealtimeModule],
  providers: [
    TypesenseClientService,
    TypesenseSitesIndexService,
    TypesenseSitesSearchService,
    TypesenseSitesSyncService,
  ],
  exports: [
    TypesenseClientService,
    TypesenseSitesIndexService,
    TypesenseSitesSearchService,
  ],
})
export class TypesenseModule {}
