/// <reference types="jest" />
jest.mock('otplib', () => ({
  generateSecret: jest.fn(() => 'test-secret'),
  generateURI: jest.fn(() => 'otpauth://totp/test'),
  verify: jest.fn(() => true),
}));

import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Role, UserStatus } from '../../src/prisma-client';
import * as bcrypt from 'bcrypt';
import { AuthAdminLoginService } from '../../src/auth/auth-admin-login.service';
import { AuthProfileService } from '../../src/auth/auth-profile.service';
import { AuthProfileReadService } from '../../src/auth/auth-profile-read.service';
import { AuthProfileAvatarService } from '../../src/auth/auth-profile-avatar.service';
import { AuthRegistrationService } from '../../src/auth/auth-registration.service';
import { AuthLoginService } from '../../src/auth/auth-login.service';
import { LOGIN_MAX_ATTEMPTS } from '../../src/auth/auth.constants';
import { AuthOtpService } from '../../src/auth/auth-otp.service';
import { AuthSessionService } from '../../src/auth/auth-session.service';
import { loadAuthEnvRuntime } from '../../src/auth/auth-env.config';
import { is2FAResponse } from '../../src/auth/types/auth-response.type';

const mockUser = {
  id: 'user-1',
  createdAt: new Date(),
  updatedAt: new Date(),
  firstName: 'Test',
  lastName: 'User',
  email: 'test@chisto.mk',
  phoneNumber: '+38970123456',
  passwordHash: '',
  role: Role.USER,
  status: UserStatus.ACTIVE,
  isPhoneVerified: true,
  pointsBalance: 0,
  totalPointsEarned: 0,
  totalPointsSpent: 0,
  lastActiveAt: null,
  avatarObjectKey: null,
  avatarUpdatedAt: null,
  organizerCertifiedAt: null,
  termsAcceptedAt: new Date('2026-06-01T00:00:00.000Z'),
  termsVersion: '1',
};

const mockAdmin = {
  ...mockUser,
  id: 'admin-1',
  email: 'admin@chisto.mk',
  phoneNumber: '+38970000001',
  role: Role.ADMIN,
};

function makePrisma() {
  return {
    user: {
      findFirst: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    userSession: {
      create: jest.fn(),
      findMany: jest.fn().mockResolvedValue([]),
      findUnique: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn().mockResolvedValue({ count: 0 }),
      count: jest.fn().mockResolvedValue(0),
    },
    adminLoginFailure: {
      findUnique: jest.fn(),
      create: jest.fn().mockResolvedValue({}),
      update: jest.fn().mockResolvedValue({}),
      deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
    },
    loginFailure: {
      findUnique: jest.fn(),
      deleteMany: jest.fn().mockResolvedValue(undefined),
      update: jest.fn(),
      create: jest.fn(),
    },
    pointTransaction: {
      aggregate: jest.fn().mockResolvedValue({ _sum: { delta: null } }),
    },
    $queryRaw: jest.fn(),
    $executeRaw: jest.fn().mockResolvedValue(1),
  };
}

function makeJwt() {
  return { sign: jest.fn().mockReturnValue('jwt-token') };
}

function makeConfig() {
  return {
    get: jest.fn((key: string) => {
      if (key === 'JWT_ACCESS_EXPIRES_IN') return '900';
      if (key === 'JWT_REFRESH_EXPIRES_DAYS') return '30';
      if (key === 'TERMS_VERSION') return '1';
      return undefined;
    }),
  };
}

function makeAudit() {
  return { log: jest.fn().mockResolvedValue(undefined) };
}

function makeEventEmitter() {
  return { emit: jest.fn(), on: jest.fn() };
}

function makeReportsUploadService() {
  return {
    signPrivateObjectKey: jest.fn().mockResolvedValue(null),
    uploadProfileAvatar: jest.fn(),
    deleteObjectByKey: jest.fn().mockResolvedValue(undefined),
  };
}

function makeGamificationService() {
  return {
    getLevelProgress: jest.fn().mockReturnValue({
      level: 1,
      pointsInLevel: 0,
      pointsToNextLevel: 36,
      levelProgress: 0,
      levelTierKey: 'numeric_1',
      levelDisplayName: 'Level 1',
    }),
  };
}

function makeRankingsService() {
  return {
    getUserWeeklySummary: jest.fn().mockResolvedValue({
      weeklyPoints: 0,
      weeklyRank: null,
      weekStartsAt: '2026-03-30T22:00:00.000Z',
      weekEndsAt: '2026-04-05T21:59:59.999Z',
    }),
  };
}

describe('Auth stack (registration, session, profile)', () => {
  let registration: AuthRegistrationService;
  let login: AuthLoginService;
  let adminLoginSvc: AuthAdminLoginService;
  let session: AuthSessionService;
  let profile: AuthProfileService;
  let profileRead: AuthProfileReadService;
  let profileAvatar: AuthProfileAvatarService;
  let prisma: ReturnType<typeof makePrisma>;
  let jwt: ReturnType<typeof makeJwt>;
  let eventEmitter: ReturnType<typeof makeEventEmitter>;
  let reportsUploadService: ReturnType<typeof makeReportsUploadService>;
  let sessionRevocation: { revokeAllForUser: jest.Mock };
  let replayCache: { get: jest.Mock; set: jest.Mock };

  beforeEach(async () => {
    prisma = makePrisma();
    jwt = makeJwt();
    const config = makeConfig();
    mockUser.passwordHash = await bcrypt.hash('StrongPass123!', 4);
    mockAdmin.passwordHash = mockUser.passwordHash;

    const audit = makeAudit();
    eventEmitter = makeEventEmitter();
    reportsUploadService = makeReportsUploadService();
    const gamificationService = makeGamificationService();
    const rankingsService = makeRankingsService();
    const env = loadAuthEnvRuntime(config as unknown as ConfigService);
    sessionRevocation = { revokeAllForUser: jest.fn().mockResolvedValue(undefined) };
    replayCache = {
      get: jest.fn().mockResolvedValue(null),
      set: jest.fn().mockResolvedValue(undefined),
    };
    session = new AuthSessionService(
      prisma as any,
      jwt as unknown as JwtService,
      reportsUploadService as any,
      audit as any,
      eventEmitter as any,
      sessionRevocation as never,
      env,
      config as unknown as ConfigService,
      replayCache as never,
    );
    const authOtp = {
      sendPhoneVerificationOtp: jest.fn().mockResolvedValue({ expiresIn: 600 }),
    } as unknown as AuthOtpService;
    registration = new AuthRegistrationService(
      prisma as any,
      eventEmitter as any,
      authOtp,
      env,
      config as unknown as ConfigService,
    );
    login = new AuthLoginService(prisma as any, session);
    adminLoginSvc = new AuthAdminLoginService(prisma as any, audit as any, session, env);
    profileRead = new AuthProfileReadService(
      prisma as any,
      reportsUploadService as any,
      gamificationService as any,
      rankingsService as any,
      config as unknown as ConfigService,
    );
    profileAvatar = new AuthProfileAvatarService(prisma as any, reportsUploadService as any);
    const accountErasure = { eraseUserAccount: jest.fn().mockResolvedValue(undefined) } as never;
    profile = new AuthProfileService(
      prisma as any,
      reportsUploadService as any,
      profileRead,
      profileAvatar,
      accountErasure,
      config as unknown as ConfigService,
      audit as any,
    );
  });

  describe('register', () => {
    it('creates a user and returns verification payload without tokens', async () => {
      prisma.user.findFirst.mockResolvedValue(null);
      prisma.user.create.mockResolvedValue({ ...mockUser, isPhoneVerified: false });

      const result = await registration.register({
        firstName: 'Test',
        lastName: 'User',
        email: 'test@chisto.mk',
        phoneNumber: '+38970123456',
        password: 'StrongPass123!',
        termsAcceptedAt: new Date().toISOString(),
        termsVersion: '1',
      });

      expect(result.userId).toBe('user-1');
      expect(result.requiresPhoneVerification).toBe(true);
      expect(result.otpExpiresIn).toBeGreaterThan(0);
      expect(prisma.user.create).toHaveBeenCalledTimes(1);
    });

    it('throws ConflictException for duplicate email', async () => {
      prisma.user.findFirst.mockResolvedValue({ id: 'x', email: 'test@chisto.mk', phoneNumber: '+389other' });

      await expect(
        registration.register({
          firstName: 'Test',
          lastName: 'User',
          email: 'test@chisto.mk',
          phoneNumber: '+38970999999',
          password: 'StrongPass123!',
          termsAcceptedAt: new Date().toISOString(),
          termsVersion: '1',
        }),
      ).rejects.toThrow(ConflictException);
    });

    it('throws ConflictException for duplicate phone', async () => {
      prisma.user.findFirst.mockResolvedValue({ id: 'x', email: 'other@x.com', phoneNumber: '+38970123456' });

      await expect(
        registration.register({
          firstName: 'Test',
          lastName: 'User',
          email: 'unique@chisto.mk',
          phoneNumber: '+38970123456',
          password: 'StrongPass123!',
          termsAcceptedAt: new Date().toISOString(),
          termsVersion: '1',
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('citizenLogin', () => {
    it('authenticates user by phone number', async () => {
      prisma.user.findUnique.mockResolvedValue(mockUser);
      prisma.userSession.create.mockResolvedValue({});

      const result = await login.citizenLogin({
        phoneNumber: '+38970123456',
        password: 'StrongPass123!',
      });

      expect(result.accessToken).toBe('jwt-token');
      expect(result.user.phoneNumber).toBe('+38970123456');
      expect(result.user.avatarUrl).toBeNull();
      expect(result.user.requiresTermsAcceptance).toBe(false);
      expect(result.user.termsVersion).toBe('1');
    });

    it('includes signed avatarUrl when user has avatarObjectKey', async () => {
      reportsUploadService.signPrivateObjectKey.mockResolvedValue(
        'https://signed.example/avatar',
      );
      prisma.user.findUnique.mockResolvedValue({
        ...mockUser,
        avatarObjectKey: 'private/avatars/user-1',
      });
      prisma.userSession.create.mockResolvedValue({});

      const result = await login.citizenLogin({
        phoneNumber: '+38970123456',
        password: 'StrongPass123!',
      });

      expect(reportsUploadService.signPrivateObjectKey).toHaveBeenCalledWith(
        'private/avatars/user-1',
      );
      expect(result.user.avatarUrl).toBe('https://signed.example/avatar');
    });

    it('rejects invalid phone number', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      await expect(
        login.citizenLogin({ phoneNumber: '+38999999999', password: 'any' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('rejects wrong password', async () => {
      prisma.user.findUnique.mockResolvedValue(mockUser);

      await expect(
        login.citizenLogin({ phoneNumber: '+38970123456', password: 'WrongPass!' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('rejects suspended user', async () => {
      prisma.user.findUnique.mockResolvedValue({ ...mockUser, status: UserStatus.SUSPENDED });

      await expect(
        login.citizenLogin({ phoneNumber: '+38970123456', password: 'StrongPass123!' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('returns TOO_MANY_ATTEMPTS when lockout window is active', async () => {
      const now = Date.now();
      prisma.loginFailure.findUnique.mockResolvedValue({
        phoneNumber: '+38970123456',
        attemptCount: LOGIN_MAX_ATTEMPTS,
        firstFailedAt: new Date(now - 60_000),
      });

      await expect(
        login.citizenLogin({ phoneNumber: '+38970123456', password: 'StrongPass123!' }),
      ).rejects.toMatchObject({
        response: expect.objectContaining({
          code: 'TOO_MANY_ATTEMPTS',
          retryAfterSeconds: expect.any(Number),
        }),
      });
    });

    it('rejects login when phone is not verified', async () => {
      prisma.loginFailure.findUnique.mockResolvedValue(null);
      prisma.user.findUnique.mockResolvedValue({
        ...mockUser,
        isPhoneVerified: false,
      });

      await expect(
        login.citizenLogin({ phoneNumber: '+38970123456', password: 'StrongPass123!' }),
      ).rejects.toMatchObject({
        response: expect.objectContaining({ code: 'PHONE_NOT_VERIFIED' }),
      });
    });

    it('clears loginFailure on successful login', async () => {
      prisma.loginFailure.findUnique.mockResolvedValue(null);
      prisma.user.findUnique.mockResolvedValue(mockUser);
      prisma.userSession.create.mockResolvedValue({});

      await login.citizenLogin({
        phoneNumber: '+38970123456',
        password: 'StrongPass123!',
      });

      expect(prisma.loginFailure.deleteMany).toHaveBeenCalledWith({
        where: { phoneNumber: '+38970123456' },
      });
    });
  });

  describe('adminLogin', () => {
    it('authenticates admin by email', async () => {
      prisma.user.findUnique.mockResolvedValue({ ...mockAdmin, totpSecret: null });
      prisma.userSession.create.mockResolvedValue({});

      const result = await adminLoginSvc.adminLogin({
        email: 'admin@chisto.mk',
        password: 'StrongPass123!',
      });

      if (is2FAResponse(result)) throw new Error('Expected direct auth, not 2FA');
      expect(result.user.role).toBe(Role.ADMIN);
    });

    it('rejects non-admin role', async () => {
      prisma.user.findUnique.mockResolvedValue(mockUser);

      await expect(
        adminLoginSvc.adminLogin({ email: 'test@chisto.mk', password: 'StrongPass123!' }),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('refresh', () => {
    it('rotates tokens when valid refresh token provided', async () => {
      const tokenId = 'a1b2c3d4e5f6';
      const fullToken = `${tokenId}.secretpart`;
      const hash = await bcrypt.hash(fullToken, 4);

      prisma.userSession.findUnique.mockResolvedValue({
        id: 'session-1',
        userId: 'user-1',
        tokenId,
        refreshTokenHash: hash,
        previousTokenHash: null,
        rotatedAt: null,
        deviceId: null,
        expiresAt: new Date(Date.now() + 86400000),
        revokedAt: null,
        user: mockUser,
      });
      prisma.userSession.updateMany.mockResolvedValue({ count: 1 });

      const result = await session.refresh(fullToken);

      expect(result.accessToken).toBe('jwt-token');
      expect(result.refreshToken).toBeDefined();
      expect(result.refreshToken).toContain('.');
      expect(result.user.avatarUrl).toBeNull();
      expect(result.user.organizerCertifiedAt).toBeNull();
      expect(prisma.userSession.findUnique).toHaveBeenCalledWith({
        where: { tokenId },
        include: { user: true },
      });
      expect(prisma.userSession.updateMany).toHaveBeenCalledWith({
        where: {
          id: 'session-1',
          revokedAt: null,
          refreshTokenHash: hash,
        },
        data: expect.objectContaining({
          previousTokenHash: hash,
          rotatedAt: expect.any(Date),
          expiresAt: expect.any(Date),
        }),
      });
      expect(prisma.userSession.create).not.toHaveBeenCalled();
    });

    it('includes organizerCertifiedAt ISO string when user is certified', async () => {
      const tokenId = 'a1b2c3d4e5f6';
      const fullToken = `${tokenId}.secretpart`;
      const hash = await bcrypt.hash(fullToken, 4);
      const certifiedAt = new Date('2026-04-21T19:46:29.350Z');

      prisma.userSession.findUnique.mockResolvedValue({
        id: 'session-1',
        userId: 'user-1',
        tokenId,
        refreshTokenHash: hash,
        previousTokenHash: null,
        rotatedAt: null,
        deviceId: null,
        expiresAt: new Date(Date.now() + 86400000),
        revokedAt: null,
        user: { ...mockUser, organizerCertifiedAt: certifiedAt },
      });
      prisma.userSession.updateMany.mockResolvedValue({ count: 1 });

      const result = await session.refresh(fullToken);

      expect(result.user.organizerCertifiedAt).toBe(certifiedAt.toISOString());
    });

    it('rejects refresh token without tokenId format', async () => {
      await expect(session.refresh('no-dot')).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('rejects invalid or unknown refresh token', async () => {
      prisma.userSession.findUnique.mockResolvedValue(null);
      await expect(
        session.refresh('tid123.wrongsecret'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('on reuse of a revoked refresh token with valid hash, emits security event without revoking all sessions', async () => {
      const tokenId = 'reuse-tid';
      const fullToken = `${tokenId}.stillvalidsecret`;
      const hash = await bcrypt.hash(fullToken, 4);

      prisma.userSession.findUnique.mockResolvedValue({
        id: 'session-revoked',
        userId: 'user-1',
        tokenId,
        refreshTokenHash: hash,
        previousTokenHash: null,
        rotatedAt: null,
        deviceId: null,
        expiresAt: new Date(Date.now() + 86400000),
        revokedAt: new Date(),
        user: mockUser,
      });

      await expect(session.refresh(fullToken)).rejects.toThrow(UnauthorizedException);
      expect(sessionRevocation.revokeAllForUser).not.toHaveBeenCalled();
      expect(eventEmitter.emit).toHaveBeenCalledWith(
        'security.refresh_token_reuse',
        expect.objectContaining({ userId: 'user-1', sessionId: 'session-revoked' }),
      );
    });
  });

  describe('logout', () => {
    it('revokes matching session', async () => {
      const tokenId = 'logout-tid';
      const fullToken = `${tokenId}.logoutsecret`;
      const hash = await bcrypt.hash(fullToken, 4);

      prisma.userSession.findUnique.mockResolvedValue({
        id: 'session-2',
        tokenId,
        refreshTokenHash: hash,
        expiresAt: new Date(Date.now() + 86400000),
        revokedAt: null,
      });
      prisma.userSession.update.mockResolvedValue({});

      await session.logout(fullToken);

      expect(prisma.userSession.findUnique).toHaveBeenCalledWith({
        where: { tokenId },
      });
      expect(prisma.userSession.update).toHaveBeenCalledWith({
        where: { id: 'session-2' },
        data: { revokedAt: expect.any(Date) },
      });
    });

    it('does nothing if token has no dot', async () => {
      await session.logout('no-match');
      expect(prisma.userSession.findUnique).not.toHaveBeenCalled();
    });

    it('does nothing if token does not match any session', async () => {
      prisma.userSession.findUnique.mockResolvedValue(null);
      await session.logout('tid.nope');
      expect(prisma.userSession.update).not.toHaveBeenCalled();
    });
  });

  describe('avatar lifecycle', () => {
    it('returns signed avatar URL from me()', async () => {
      const reportsUpload = {
        signPrivateObjectKey: jest.fn().mockResolvedValue('https://signed/avatar'),
      };
      (profileRead as any).reportsUploadService = reportsUpload;
      prisma.user.findUnique.mockResolvedValue({
        ...mockUser,
        totpSecret: null,
        avatarObjectKey: 'profile-avatars/user-1/a.webp',
      });

      const result = await profile.me({
        userId: 'user-1',
        role: Role.USER,
        email: 'u@x.com',
        phoneNumber: '+38970000000',
      });
      expect(result.avatarUrl).toBe('https://signed/avatar');
      expect(reportsUpload.signPrivateObjectKey).toHaveBeenCalledWith('profile-avatars/user-1/a.webp');
    });

    it('uploads avatar and updates user key', async () => {
      const reportsUpload = {
        uploadProfileAvatar: jest.fn().mockResolvedValue('profile-avatars/user-1/new.webp'),
        signPrivateObjectKey: jest.fn().mockResolvedValue('https://signed/new'),
        deleteObjectByKey: jest.fn().mockResolvedValue(undefined),
      };
      (profileAvatar as any).reportsUploadService = reportsUpload;
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        status: UserStatus.ACTIVE,
        avatarObjectKey: 'profile-avatars/user-1/old.webp',
      });
      const result = await profile.uploadAvatar('user-1', {
        buffer: Buffer.from('x'),
        mimetype: 'image/jpeg',
        size: 1,
        originalname: 'a.jpg',
      } as Express.Multer.File);

      expect(result.avatarUrl).toBe('https://signed/new');
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { avatarObjectKey: 'profile-avatars/user-1/new.webp', avatarUpdatedAt: expect.any(Date) },
      });
      expect(reportsUpload.deleteObjectByKey).toHaveBeenCalledWith('profile-avatars/user-1/old.webp');
    });
  });
});
