import {
  Injectable,
  InternalServerErrorException,
  Optional,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { Role, UserStatus } from '../prisma-client';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from './types/authenticated-user.type';
import { UserAuthSnapshotCacheService } from './user-auth-snapshot-cache.service';
import { resolveJwtSecretsFromEnv, secretForKid } from './jwt-secret.resolver';

type JwtPayload = {
  sub: string;
  role: Role;
  sid?: string;
};

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    @Optional() configService: ConfigService | null,
    private readonly prisma: PrismaService,
    private readonly authSnapshotCache: UserAuthSnapshotCacheService,
  ) {
    const entries = resolveJwtSecretsFromEnv(
      configService
        ? {
            JWT_SECRET: configService.get<string>('JWT_SECRET'),
            JWT_KID: configService.get<string>('JWT_KID'),
            JWT_SECRET_PREVIOUS: configService.get<string>('JWT_SECRET_PREVIOUS'),
            JWT_KID_PREVIOUS: configService.get<string>('JWT_KID_PREVIOUS'),
          }
        : process.env,
    );
    const defaultSecret = entries[0]?.secret;

    if (!defaultSecret) {
      throw new InternalServerErrorException({
        code: 'JWT_SECRET_MISSING',
        message: 'JWT_SECRET is not configured',
      });
    }

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKeyProvider: (
        _request: unknown,
        rawJwtToken: string,
        done: (err: Error | null, secret?: string) => void,
      ) => {
        try {
          const header = JSON.parse(
            Buffer.from(rawJwtToken.split('.')[0] ?? '', 'base64url').toString('utf8'),
          ) as { kid?: string };
          const secret = secretForKid(header.kid, entries) ?? defaultSecret;
          done(null, secret);
        } catch {
          done(null, defaultSecret);
        }
      },
      algorithms: ['HS256'],
      issuer: 'chisto-api',
      audience: 'chisto-api',
    });
  }

  async validate(payload: JwtPayload): Promise<AuthenticatedUser> {
    if (!payload.sid?.trim()) {
      throw new UnauthorizedException({
        code: 'SESSION_REQUIRED',
        message: 'Access token is not bound to a session',
      });
    }

    const session = await this.prisma.userSession.findFirst({
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

    let snapshot = this.authSnapshotCache.get(payload.sub);
    if (!snapshot) {
      const dbUser = await this.prisma.user.findUnique({
        where: { id: payload.sub },
        select: { status: true, role: true, email: true, phoneNumber: true },
      });
      if (!dbUser) {
        throw new UnauthorizedException({
          code: 'ACCOUNT_NOT_ACTIVE',
          message: 'Account is not active or has been deleted',
        });
      }
      snapshot = {
        status: dbUser.status,
        role: dbUser.role,
        email: dbUser.email,
        phoneNumber: dbUser.phoneNumber,
      };
      this.authSnapshotCache.set(payload.sub, snapshot);
    }

    if (snapshot.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        code: 'ACCOUNT_NOT_ACTIVE',
        message: 'Account is not active or has been deleted',
      });
    }

    return {
      userId: payload.sub,
      email: snapshot.email,
      phoneNumber: snapshot.phoneNumber,
      role: snapshot.role,
      sessionId: payload.sid,
    };
  }
}
