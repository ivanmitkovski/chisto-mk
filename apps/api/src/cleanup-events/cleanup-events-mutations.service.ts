import { Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { BulkModerateCleanupEventsDto } from './dto/bulk-moderate-cleanup-events.dto';
import { CreateCleanupEventDto } from './dto/create-cleanup-event.dto';
import { ListCheckInRiskSignalsQueryDto } from './dto/list-check-in-risk-signals-query.dto';
import { PatchCleanupEventDto } from './dto/patch-cleanup-event.dto';
import { CleanupEventsBulkModerateMutationService } from './cleanup-events-mutation-bulk.service';
import { CleanupEventsCheckInRiskSignalsService } from './cleanup-events-check-in-risk-signals.service';
import { CleanupEventsCreateMutationService } from './cleanup-events-mutation-create.service';
import { CleanupEventsPatchMutationService } from './cleanup-events-mutation-patch.service';

@Injectable()
export class CleanupEventsMutationsService {
  constructor(
    private readonly createMutation: CleanupEventsCreateMutationService,
    private readonly patchMutation: CleanupEventsPatchMutationService,
    private readonly bulkMutation: CleanupEventsBulkModerateMutationService,
    private readonly checkInRiskSignals: CleanupEventsCheckInRiskSignalsService,
  ) {}

  create(dto: CreateCleanupEventDto, actor: AuthenticatedUser) {
    return this.createMutation.create(dto, actor);
  }

  patch(id: string, dto: PatchCleanupEventDto, actor: AuthenticatedUser) {
    return this.patchMutation.patch(id, dto, actor);
  }

  bulkModerate(dto: BulkModerateCleanupEventsDto, actor: AuthenticatedUser) {
    return this.bulkMutation.bulkModerate(dto, actor);
  }

  listCheckInRiskSignals(query: ListCheckInRiskSignalsQueryDto) {
    return this.checkInRiskSignals.listCheckInRiskSignals(query);
  }
}
