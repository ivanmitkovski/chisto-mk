import { Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { BulkModerateCleanupEventsDto } from '../dto/bulk-moderate-cleanup-events.dto';
import { CreateCleanupEventDto } from '../dto/create-cleanup-event.dto';
import { CreateCleanupEventModerationNoteDto } from '../dto/create-cleanup-event-moderation-note.dto';
import { ListCheckInRiskSignalsQueryDto } from '../dto/list-check-in-risk-signals-query.dto';
import { PatchCheckInRiskSignalDto } from '../dto/patch-check-in-risk-signal.dto';
import { ListCleanupEventsQueryDto } from '../dto/list-cleanup-events-query.dto';
import { PatchCleanupEventDto } from '../dto/patch-cleanup-event.dto';
import { CleanupEventsAnalyticsService } from '../services/cleanup-events-analytics.service';
import { CleanupEventsListService } from '../services/cleanup-events-list.service';
import { CleanupEventsModerationNotesService } from '../services/cleanup-events-moderation-notes.service';
import { CleanupEventsMutationsService } from '../services/cleanup-events-mutations.service';
import { CleanupEventsParticipantsAdminService } from '../services/cleanup-events-participants-admin.service';

/**
 * Facade for admin cleanup event listing, analytics passthrough, and write operations.
 */
@Injectable()
export class CleanupEventsService {
  constructor(
    private readonly cleanupEventsList: CleanupEventsListService,
    private readonly cleanupEventsMutations: CleanupEventsMutationsService,
    private readonly cleanupEventsAnalytics: CleanupEventsAnalyticsService,
    private readonly cleanupEventsNotes: CleanupEventsModerationNotesService,
    private readonly cleanupEventsParticipantsAdmin: CleanupEventsParticipantsAdminService,
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

  removeParticipant(id: string, userId: string, actor: AuthenticatedUser) {
    return this.cleanupEventsParticipantsAdmin.removeParticipant(id, userId, actor);
  }

  listNotes(id: string) {
    return this.cleanupEventsNotes.listNotes(id);
  }

  createNote(id: string, dto: CreateCleanupEventModerationNoteDto, actor: AuthenticatedUser) {
    return this.cleanupEventsNotes.createNote(id, dto, actor);
  }

  deleteNote(id: string, noteId: string, actor: AuthenticatedUser) {
    return this.cleanupEventsNotes.deleteNote(id, noteId, actor);
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

  patchCheckInRiskSignal(
    id: string,
    dto: PatchCheckInRiskSignalDto,
    actor: AuthenticatedUser,
  ) {
    return this.cleanupEventsMutations.patchCheckInRiskSignal(id, dto, actor);
  }
}
