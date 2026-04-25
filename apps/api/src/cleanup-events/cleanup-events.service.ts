import { Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { BulkModerateCleanupEventsDto } from './dto/bulk-moderate-cleanup-events.dto';
import { CreateCleanupEventDto } from './dto/create-cleanup-event.dto';
import { ListCheckInRiskSignalsQueryDto } from './dto/list-check-in-risk-signals-query.dto';
import { ListCleanupEventsQueryDto } from './dto/list-cleanup-events-query.dto';
import { PatchCleanupEventDto } from './dto/patch-cleanup-event.dto';
import { CleanupEventsAnalyticsService } from './cleanup-events-analytics.service';
import { CleanupEventsListService } from './cleanup-events-list.service';
import { CleanupEventsMutationsService } from './cleanup-events-mutations.service';

/**
 * Facade for admin cleanup event listing, analytics passthrough, and write operations.
 */
@Injectable()
export class CleanupEventsService {
  constructor(
    private readonly cleanupEventsList: CleanupEventsListService,
    private readonly cleanupEventsMutations: CleanupEventsMutationsService,
    private readonly cleanupEventsAnalytics: CleanupEventsAnalyticsService,
  ) {}

  list(query: ListCleanupEventsQueryDto) {
    return this.cleanupEventsList.list(query);
  }

  findOne(id: string) {
    return this.cleanupEventsList.findOne(id);
  }

  getAnalytics(id: string) {
    return this.cleanupEventsAnalytics.getAnalytics(id);
  }

  listParticipants(id: string) {
    return this.cleanupEventsAnalytics.listParticipants(id);
  }

  listAuditTrail(id: string, query: { page?: number; limit?: number }) {
    return this.cleanupEventsAnalytics.listAuditTrail(id, query);
  }

  create(dto: CreateCleanupEventDto, actor: AuthenticatedUser) {
    return this.cleanupEventsMutations.create(dto, actor);
  }

  patch(id: string, dto: PatchCleanupEventDto, actor: AuthenticatedUser) {
    return this.cleanupEventsMutations.patch(id, dto, actor);
  }

  bulkModerate(dto: BulkModerateCleanupEventsDto, actor: AuthenticatedUser) {
    return this.cleanupEventsMutations.bulkModerate(dto, actor);
  }

  listCheckInRiskSignals(query: ListCheckInRiskSignalsQueryDto) {
    return this.cleanupEventsMutations.listCheckInRiskSignals(query);
  }
}
