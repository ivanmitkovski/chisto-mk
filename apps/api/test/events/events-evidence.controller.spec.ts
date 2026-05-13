/// <reference types="jest" />

import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { Role } from '../../src/prisma-client';
import { EventsEvidenceController } from '../../src/events/events-evidence.controller';
import { EventEvidenceService } from '../../src/events/event-evidence.service';

function user(id: string): AuthenticatedUser {
  return {
    userId: id,
    email: `${id}@test.chisto.mk`,
    phoneNumber: '+38970000000',
    role: Role.USER,
  };
}

describe('EventsEvidenceController', () => {
  const listForEvent = jest.fn();
  const addPhoto = jest.fn();
  const deletePhoto = jest.fn();

  let controller: EventsEvidenceController;

  beforeEach(() => {
    listForEvent.mockReset();
    addPhoto.mockReset();
    deletePhoto.mockReset();
    controller = new EventsEvidenceController({
      listForEvent,
      addPhoto,
      deletePhoto,
    } as unknown as EventEvidenceService);
  });

  it('listEvidence forwards id and user', async () => {
    const u = user('u1');
    const id = 'c012345678901234567890123';
    const rows = [{ id: 'ev-1' }];
    listForEvent.mockResolvedValue(rows);

    const result = await controller.listEvidence(u, id);

    expect(listForEvent).toHaveBeenCalledWith(id, u);
    expect(result).toBe(rows);
  });

  it('uploadEvidence forwards id, user, file, and body kind', async () => {
    const u = user('u1');
    const id = 'c012345678901234567890123';
    const file = { buffer: Buffer.from('x'), mimetype: 'image/jpeg' } as Express.Multer.File;
    const body = { kind: 'AFTER' as const };
    const created = { id: 'ev-2' };
    addPhoto.mockResolvedValue(created);

    const result = await controller.uploadEvidence(u, id, file, body);

    expect(addPhoto).toHaveBeenCalledWith(id, u, file, 'AFTER');
    expect(result).toBe(created);
  });

  it('deleteEvidence forwards event id, photo id, and user', async () => {
    const u = user('u1');
    const eventId = 'c012345678901234567890123';
    const photoId = 'c012345678901234567890124';
    deletePhoto.mockResolvedValue(undefined);

    const result = await controller.deleteEvidence(u, eventId, photoId);

    expect(deletePhoto).toHaveBeenCalledWith(eventId, photoId, u);
    expect(result).toEqual({ ok: true });
  });
});
