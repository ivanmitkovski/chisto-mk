import { InternalServerErrorException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Socket } from 'socket.io';
import * as jwt from 'jsonwebtoken';
import { PrismaService } from '../../prisma/prisma.service';
import { UserStatus } from '../../prisma-client';
import { resolveJwtSecretsFromEnv, secretForKid } from '../../auth/util/jwt-secret.resolver';

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
  _config: ConfigService,
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

  const jwtEntries = resolveJwtSecretsFromEnv();
  if (jwtEntries.length === 0) {
    throw new InternalServerErrorException({
      code: 'JWT_SECRET_MISSING',
      message: 'JWT_SECRET is not configured',
    });
  }

  let payload: { sub: string; sid?: string };
  try {
    const header = JSON.parse(
      Buffer.from(token.split('.')[0] ?? '', 'base64url').toString('utf8'),
    ) as { kid?: string };
    const secret = secretForKid(header.kid, jwtEntries) ?? jwtEntries[0]!.secret;
    payload = jwt.verify(token, secret, {
      algorithms: ['HS256'],
      issuer: 'chisto-api',
      audience: 'chisto-api',
    }) as { sub: string; sid?: string };
  } catch {
    throw new UnauthorizedException({
      code: 'INVALID_TOKEN',
      message: 'Invalid or expired authentication token',
    });
  }

  if (!payload.sid?.trim()) {
    throw new UnauthorizedException({
      code: 'SESSION_REQUIRED',
      message: 'Access token is not bound to a session',
    });
  }

  const session = await prisma.userSession.findFirst({
    where: {
      id: payload.sid,
      userId: payload.sub,
      revokedAt: null,
      expiresAt: { gt: new Date() },
    },
    select: { id: true },
  });
  if (!session) {
    throw new UnauthorizedException({
      code: 'SESSION_REVOKED',
      message: 'Session is no longer valid',
    });
  }

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
