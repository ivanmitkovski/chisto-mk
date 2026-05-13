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

type JwtPayload = {
  sub: string;
  email: string;
  phoneNumber: string;
  role: Role;
  sid?: string;
};

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    @Optional() configService: ConfigService | null,
    private readonly prisma: PrismaService,
  ) {
    const secret =
      configService?.get<string>('JWT_SECRET')?.trim() ?? process.env.JWT_SECRET?.trim();

    if (!secret) {
      throw new InternalServerErrorException({
        code: 'JWT_SECRET_MISSING',
        message: 'JWT_SECRET is not configured',
      });
    }

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
      issuer: 'chisto-api',
      audience: 'chisto-api',
    });
  }

  async validate(payload: JwtPayload): Promise<AuthenticatedUser> {
    const dbUser = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: { status: true },
    });

    if (!dbUser || dbUser.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        code: 'ACCOUNT_NOT_ACTIVE',
        message: 'Account is not active or has been deleted',
      });
    }

    // SECURITY: Bind access tokens to a live session row so logout / refresh rotation revokes JWTs that carry sid.
    if (payload.sid) {
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
    }

    const authUser: AuthenticatedUser = {
      userId: payload.sub,
      email: payload.email,
      phoneNumber: payload.phoneNumber,
      role: payload.role,
    };
    if (payload.sid) {
      authUser.sessionId = payload.sid;
    }
    return authUser;
  }
}
