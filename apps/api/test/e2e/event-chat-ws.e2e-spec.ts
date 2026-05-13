/// <reference types="jest" />

import type { AddressInfo } from 'node:net';
import type { INestApplication } from '@nestjs/common';
import { io, type ManagerOptions, type SocketOptions } from 'socket.io-client';
import { createE2eApplication } from './helpers/bootstrap-app';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import { registerCitizen } from './helpers/auth-helper';
import { PrismaService } from '../../src/prisma/prisma.service';

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

describe('Event chat WebSocket (e2e)', () => {
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
    await deleteUsersByEmailPrefix(prisma, 'e2e_ws_chat_');
    await app.close();
  });

  it('emits AUTH_FAILED when handshake token is invalid', async () => {
    const client = io(`${baseUrl}/chat`, wsClientOptions('not-a-valid-jwt'));
    await new Promise<void>((resolve, reject) => {
      const t = setTimeout(() => {
        client.close();
        reject(new Error('timeout waiting for WS auth failure'));
      }, 15_000);
      client.on('error', (payload: { code?: string }) => {
        if (payload?.code === 'AUTH_FAILED') {
          clearTimeout(t);
          client.close();
          resolve();
        }
      });
      client.on('connect_error', () => {
        clearTimeout(t);
        client.close();
        reject(new Error('unexpected connect_error (expected in-app AUTH_FAILED)'));
      });
    });
  });

  it('connects on /chat namespace with valid access token', async () => {
    const u = await registerCitizen(app, 'ws_chat');
    const client = io(`${baseUrl}/chat`, wsClientOptions(u.accessToken));
    await new Promise<void>((resolve, reject) => {
      const t = setTimeout(() => {
        client.close();
        reject(new Error('WS connect timeout'));
      }, 15_000);
      client.once('connect', () => {
        clearTimeout(t);
        client.close();
        resolve();
      });
      client.once('connect_error', (err: Error) => {
        clearTimeout(t);
        client.close();
        reject(err);
      });
    });
  });
});
