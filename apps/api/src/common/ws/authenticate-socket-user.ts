import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Socket } from 'socket.io';
import * as jwt from 'jsonwebtoken';
import { PrismaService } from '../../prisma/prisma.service';
import { UserStatus } from '../../prisma-client';

export type AuthenticatedSocketUser = {
  userId: string;
  displayName: string;
};

/**
 * Validates JWT from Socket.IO handshake (`auth.token` or `Authorization: Bearer`).
 * Used by all citizen-facing WS gateways for consistent auth behaviour.
 */
export async function authenticateSocketUser(
  client: Socket,
  config: ConfigService,
  prisma: PrismaService,
): Promise<AuthenticatedSocketUser> {
  const authHeader = client.handshake.headers.authorization;
  let tokenFromHeader: string | undefined;
  if (typeof authHeader === 'string') {
    const match = authHeader.match(/^Bearer\s+(.+)$/i);
    tokenFromHeader = match?.[1]?.trim();
  }
  const token = (client.handshake.auth?.token as string) || tokenFromHeader;

  if (!token) {
    throw new UnauthorizedException('Missing token');
  }

  const secret = config.get<string>('JWT_SECRET');
  if (!secret) {
    throw new Error('JWT_SECRET not configured');
  }

  const payload = jwt.verify(token, secret, { algorithms: ['HS256'] }) as {
    sub: string;
    email: string;
  };

  const user = await prisma.user.findUnique({
    where: { id: payload.sub },
    select: { id: true, firstName: true, lastName: true, status: true },
  });

  if (!user || user.status !== UserStatus.ACTIVE) {
    throw new UnauthorizedException('User not active');
  }

  return {
    userId: user.id,
    displayName: `${user.firstName} ${user.lastName}`.trim(),
  };
}
