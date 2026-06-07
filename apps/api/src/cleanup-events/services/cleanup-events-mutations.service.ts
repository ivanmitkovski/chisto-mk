import { Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { BulkModerateCleanupEventsDto } from '../dto/bulk-moderate-cleanup-events.dto';
import { CreateCleanupEventDto } from '../dto/create-cleanup-event.dto';
import { ListCheckInRiskSignalsQueryDto } from '../dto/list-check-in-risk-signals-query.dto';
import { PatchCheckInRiskSignalDto } from '../dto/patch-check-in-risk-signal.dto';
import { PatchCleanupEventDto } from '../dto/patch-cleanup-event.dto';
import { CleanupEventsBulkModerateMutationService } from '../services/cleanup-events-mutation-bulk.service';
import { CleanupEventsCheckInRiskSignalsService } from '../services/cleanup-events-check-in-risk-signals.service';
import { CleanupEventsCreateMutationService } from '../services/cleanup-events-mutation-create.service';
import { CleanupEventsPatchMutationService } from '../services/cleanup-events-mutation-patch.service';

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

  patchCheckInRiskSignal(
    id: string,
    dto: PatchCheckInRiskSignalDto,
    actor: AuthenticatedUser,
  ) {
    return this.checkInRiskSignals.patchCheckInRiskSignal(id, dto, actor);
  }
}
