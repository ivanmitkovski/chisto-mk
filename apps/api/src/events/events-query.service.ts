import { Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { FindEventQueryDto } from './dto/find-event-query.dto';
import { ListEventParticipantsQueryDto } from './dto/list-event-participants-query.dto';
import { ListEventsQueryDto } from './dto/list-events-query.dto';
import { EventsDetailQueryService } from './events-detail-query.service';
import { EventsListQueryService } from './events-list-query.service';

/**
 * Facade for event read paths; delegates to list/detail query services.
 */
@Injectable()
export class EventsQueryService {
  constructor(
    private readonly listQuery: EventsListQueryService,
    private readonly detailQuery: EventsDetailQueryService,
  ) {}

  list(user: AuthenticatedUser, query: ListEventsQueryDto) {
    return this.listQuery.list(user, query);
  }

  findOne(id: string, user: AuthenticatedUser, geo?: FindEventQueryDto) {
    return this.detailQuery.findOne(id, user, geo);
  }

  listParticipants(
    id: string,
    user: AuthenticatedUser,
    query: ListEventParticipantsQueryDto,
  ) {
    return this.detailQuery.listParticipants(id, user, query);
  }
}
