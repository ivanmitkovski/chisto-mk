/// <reference types="jest" />

import { CleanupEventsController } from '../../src/cleanup-events/cleanup-events.controller';
import { CleanupEventsService } from '../../src/cleanup-events/cleanup-events.service';

describe('CleanupEventsController', () => {
  let controller: CleanupEventsController;
  const list = jest.fn();
  const findOne = jest.fn();
  const getAnalytics = jest.fn();
  const listParticipants = jest.fn();
  const listAuditTrail = jest.fn();
  const create = jest.fn();
  const patch = jest.fn();
  const bulkModerate = jest.fn();
  const listCheckInRiskSignals = jest.fn();

  beforeEach(() => {
    list.mockReset();
    findOne.mockReset();
    getAnalytics.mockReset();
    listParticipants.mockReset();
    listAuditTrail.mockReset();
    create.mockReset();
    patch.mockReset();
    bulkModerate.mockReset();
    listCheckInRiskSignals.mockReset();

    controller = new CleanupEventsController({
      list,
      findOne,
      getAnalytics,
      listParticipants,
      listAuditTrail,
      create,
      patch,
      bulkModerate,
      listCheckInRiskSignals,
    } as unknown as CleanupEventsService);
  });

  it('list delegates to service with query', () => {
    const query = { page: 2, limit: 10 } as never;
    list.mockReturnValue('listed');
    expect(controller.list(query)).toBe('listed');
    expect(list).toHaveBeenCalledWith(query);
  });

  it('analytics delegates to service', () => {
    getAnalytics.mockReturnValue('stats');
    expect(controller.analytics('evt-1')).toBe('stats');
    expect(getAnalytics).toHaveBeenCalledWith('evt-1');
  });

  it('listAudit maps page and limit', () => {
    listAuditTrail.mockReturnValue('audit');
    expect(controller.listAudit('evt-1', { page: 2, limit: 25 } as never)).toBe('audit');
    expect(listAuditTrail).toHaveBeenCalledWith('evt-1', { page: 2, limit: 25 });
  });

  it('bulkModerate passes dto and actor', () => {
    const dto = { eventIds: ['a'], action: 'APPROVED', clientJobId: 'job-1' } as never;
    const actor = { userId: 'admin-1' } as never;
    bulkModerate.mockReturnValue('bulk');
    expect(controller.bulkModerate(dto, actor)).toBe('bulk');
    expect(bulkModerate).toHaveBeenCalledWith(dto, actor);
  });
});
