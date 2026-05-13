/// <reference types="jest" />

import type { AddressInfo } from 'node:net';
import type { INestApplication } from '@nestjs/common';
import { io, type ManagerOptions, type SocketOptions } from 'socket.io-client';
import { createE2eApplication } from './helpers/bootstrap-app';
import {
  createApprovedEventWithParticipant,
  deleteApprovedEventFixture,
} from './helpers/approved-event-with-participant';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import { registerCitizen } from './helpers/auth-helper';
import { PrismaService } from '../../src/prisma/prisma.service';

const TYPING_THROTTLE_MS = 2600;

function wsClientOptions(token?: string): Partial<ManagerOptions & SocketOptions> {
  const opts: Partial<ManagerOptions & SocketOptions> = {
    transports: ['websocket'],
    extraHeaders: { Origin: 'http://localhost:3000' },
  };
  if (token) {
    opts.auth = { token };
  }
  return opts;
}

describe('Event chat WebSocket journey (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let baseUrl: string;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
    await app.listen(0);
    const addr = app.getHttpServer().address() as AddressInfo;
    baseUrl = `http://127.0.0.1:${addr.port}`;
  });

  afterAll(async () => {
    await deleteUsersByEmailPrefix(prisma, 'e2e_ws_journey_');
    await app.close();
  });

  it('fan-out typing:update to peer in room after join (throttle-aware)', async () => {
    const organizer = await registerCitizen(app, 'ws_journey_org');
    const participant = await registerCitizen(app, 'ws_journey_part');
    const orgUser = await prisma.user.findFirstOrThrow({ where: { email: organizer.email } });
    const participantUser = await prisma.user.findFirstOrThrow({ where: { email: participant.email } });
    const fixture = await createApprovedEventWithParticipant(prisma, orgUser.id, participantUser.id);

    const listener = io(`${baseUrl}/chat`, wsClientOptions(participant.accessToken));
    const emitter = io(`${baseUrl}/chat`, wsClientOptions(organizer.accessToken));

    try {
      await new Promise<void>((resolve, reject) => {
        const t = setTimeout(() => {
          reject(new Error('timeout waiting for typing:update'));
        }, 25_000);

        const done = (): void => {
          clearTimeout(t);
          resolve();
        };
        const fail = (err: Error): void => {
          clearTimeout(t);
          reject(err);
        };

        listener.once('connect_error', fail);
        emitter.once('connect_error', fail);

        let connected = 0;
        const onBothConnected = (): void => {
          connected += 1;
          if (connected !== 2) {
            return;
          }
          listener.emit('join', { eventId: fixture.eventId });
          emitter.emit('join', { eventId: fixture.eventId });

          listener.once('typing:update', (payload: { eventId?: string; userId?: string; typing?: boolean }) => {
            try {
              expect(payload.eventId).toBe(fixture.eventId);
              expect(payload.userId).toBe(orgUser.id);
              expect(payload.typing).toBe(true);
              done();
            } catch (e) {
              clearTimeout(t);
              reject(e instanceof Error ? e : new Error(String(e)));
            }
          });

          void (async () => {
            await new Promise((r) => setTimeout(r, TYPING_THROTTLE_MS));
            emitter.emit('typing', { eventId: fixture.eventId, typing: true });
          })();
        };

        listener.once('connect', onBothConnected);
        emitter.once('connect', onBothConnected);
      });
    } finally {
      listener.close();
      emitter.close();
      await deleteApprovedEventFixture(prisma, fixture);
    }
  });
});
