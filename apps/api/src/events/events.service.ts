import { Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { CheckEventConflictQueryDto } from './dto/check-event-conflict-query.dto';
import { CreatePublicEventDto } from './dto/create-public-event.dto';
import { ListEventParticipantsQueryDto } from './dto/list-event-participants-query.dto';
import { FindEventQueryDto } from './dto/find-event-query.dto';
import { ListEventsQueryDto } from './dto/list-events-query.dto';
import { PatchEventLifecycleDto } from './dto/patch-event-lifecycle.dto';
import { PatchEventReminderDto } from './dto/patch-event-reminder.dto';
import { PatchPublicEventDto } from './dto/patch-public-event.dto';
import { EventsCreationService } from './events-creation.service';
import { EventsLifecycleParticipationService } from './events-lifecycle-participation.service';
import { EventsQueryService } from './events-query.service';
import { EventsUpdateService } from './events-update.service';

/**
 * Public façade for the events bounded context. Implementation is split across
 * query / creation / update / lifecycle-participation services to respect size limits.
 */
@Injectable()
export class EventsService {
  constructor(
    private readonly query: EventsQueryService,
    private readonly creation: EventsCreationService,
    private readonly updates: EventsUpdateService,
    private readonly lifecycle: EventsLifecycleParticipationService,
  ) {}

  list(user: AuthenticatedUser, query: ListEventsQueryDto) {
    return this.query.list(user, query);
  }

  findPublicShareCard(id: string) {
    return this.query.findPublicShareCard(id);
  }

  findOne(id: string, user: AuthenticatedUser, geo?: FindEventQueryDto) {
    return this.query.findOne(id, user, geo);
  }

  listParticipants(
    id: string,
    user: AuthenticatedUser,
    query: ListEventParticipantsQueryDto,
  ) {
    return this.query.listParticipants(id, user, query);
  }

  checkScheduleConflictPreview(query: CheckEventConflictQueryDto) {
    return this.query.checkScheduleConflictPreview(query);
  }

  create(dto: CreatePublicEventDto, user: AuthenticatedUser) {
    return this.creation.create(dto, user);
  }

  patchEvent(id: string, dto: PatchPublicEventDto, user: AuthenticatedUser) {
    return this.updates.patchEvent(id, dto, user);
  }

  patchLifecycle(id: string, dto: PatchEventLifecycleDto, user: AuthenticatedUser) {
    return this.lifecycle.patchLifecycle(id, dto, user);
  }

  join(id: string, user: AuthenticatedUser) {
    return this.lifecycle.join(id, user);
  }

  leave(id: string, user: AuthenticatedUser) {
    return this.lifecycle.leave(id, user);
  }

  patchReminder(id: string, dto: PatchEventReminderDto, user: AuthenticatedUser) {
    return this.lifecycle.patchReminder(id, dto, user);
  }

  appendAfterImages(id: string, files: Express.Multer.File[], user: AuthenticatedUser) {
    return this.lifecycle.appendAfterImages(id, files, user);
  }

  getAnalytics(id: string, user: AuthenticatedUser) {
    return this.lifecycle.getAnalytics(id, user);
  }
}
