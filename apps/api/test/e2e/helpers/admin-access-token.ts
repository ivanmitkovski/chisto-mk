import { randomUUID } from 'node:crypto';
import * as jwt from 'jsonwebtoken';
import { PrismaService } from '../../../src/prisma/prisma.service';
import { Role } from '../../../src/prisma-client';
import { uniquePhone } from './auth-helper';

const PLACEHOLDER_PASSWORD_HASH = '$2b$04$placeholderhashplaceholderhashpl';

export type E2eAdminAccessToken = {
  token: string;
  userId: string;
  email: string;
};

/** Creates an admin-panel user + session and returns a signed access JWT for e2e calls. */
export async function createE2eAdminAccessToken(
  prisma: PrismaService,
  options?: { emailPrefix?: string; role?: Role },
): Promise<E2eAdminAccessToken> {
  const emailPrefix = options?.emailPrefix ?? 'e2e_admin';
  const role = options?.role ?? Role.ADMIN;
  const email = `${emailPrefix}_${Date.now()}@test.local`;

  const adminUser = await prisma.user.create({
    data: {
      firstName: 'Admin',
      lastName: 'E2E',
      email,
      phoneNumber: uniquePhone(),
      passwordHash: PLACEHOLDER_PASSWORD_HASH,
      role,
      isPhoneVerified: true,
      termsAcceptedAt: new Date(),
      termsVersion: '1',
    },
  });

  const session = await prisma.userSession.create({
    data: {
      userId: adminUser.id,
      tokenId: randomUUID(),
      refreshTokenHash: 'hash',
      expiresAt: new Date(Date.now() + 86400000),
    },
  });

  const secret = process.env.JWT_SECRET ?? 'ci_jwt_secret_must_be_at_least_thirty_two_chars';
  const token = jwt.sign(
    { sub: adminUser.id, role, sid: session.id },
    secret,
    {
      expiresIn: 900,
      issuer: 'chisto-api',
      audience: 'chisto-api',
      header: { kid: 'default', alg: 'HS256' },
    },
  );

  return { token, userId: adminUser.id, email };
}
