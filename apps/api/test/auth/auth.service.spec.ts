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
import { AuthService } from '../../src/auth/auth.service';
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
  isPhoneVerified: false,
  pointsBalance: 0,
  totalPointsEarned: 0,
  totalPointsSpent: 0,
  lastActiveAt: null,
  avatarObjectKey: null,
  avatarUpdatedAt: null,
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
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn().mockResolvedValue({ count: 0 }),
      count: jest.fn().mockResolvedValue(0),
    },
    adminLoginFailure: {
      findUnique: jest.fn(),
      upsert: jest.fn(),
      update: jest.fn(),
      deleteMany: jest.fn().mockResolvedValue(undefined),
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
      return undefined;
    }),
  };
}

function makeOtpService() {
  return {
    createAndSend: jest.fn().mockResolvedValue(undefined),
    verify: jest.fn().mockResolvedValue(true),
  };
}

function makeOtpSender() {
  return { sendOtp: jest.fn().mockResolvedValue(undefined) };
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

describe('AuthService', () => {
  let service: AuthService;
  let prisma: ReturnType<typeof makePrisma>;
  let jwt: ReturnType<typeof makeJwt>;
  let eventEmitter: ReturnType<typeof makeEventEmitter>;
  let reportsUploadService: ReturnType<typeof makeReportsUploadService>;

  beforeEach(async () => {
    prisma = makePrisma();
    jwt = makeJwt();
    const config = makeConfig();
    const otpSender = makeOtpSender();
    mockUser.passwordHash = await bcrypt.hash('StrongPass123!', 4);
    mockAdmin.passwordHash = mockUser.passwordHash;

    const otpService = makeOtpService();
    const audit = makeAudit();
    eventEmitter = makeEventEmitter();
    reportsUploadService = makeReportsUploadService();
    const gamificationService = makeGamificationService();
    const rankingsService = makeRankingsService();
    service = new AuthService(
      prisma as any,
      jwt as unknown as JwtService,
      otpService as any,
      config as unknown as ConfigService,
      otpSender as any,
      audit as any,
      eventEmitter as any,
      reportsUploadService as any,
      gamificationService as any,
      rankingsService as any,
    );
  });

  describe('register', () => {
    it('creates a user and returns tokens', async () => {
      prisma.user.findFirst.mockResolvedValue(null);
      prisma.user.create.mockResolvedValue(mockUser);
      prisma.userSession.create.mockResolvedValue({});

      const result = await service.register({
        firstName: 'Test',
        lastName: 'User',
        email: 'test@chisto.mk',
        phoneNumber: '+38970123456',
        password: 'StrongPass123!',
      });

      expect(result.accessToken).toBe('jwt-token');
      expect(result.refreshToken).toBeDefined();
      expect(result.user.id).toBe('user-1');
      expect(result.user.avatarUrl).toBeNull();
      expect(prisma.user.create).toHaveBeenCalledTimes(1);
      expect(prisma.userSession.create).toHaveBeenCalledTimes(1);
    });

    it('throws ConflictException for duplicate email', async () => {
      prisma.user.findFirst.mockResolvedValue({ id: 'x', email: 'test@chisto.mk', phoneNumber: '+389other' });

      await expect(
        service.register({
          firstName: 'Test',
          lastName: 'User',
          email: 'test@chisto.mk',
          phoneNumber: '+38970999999',
          password: 'StrongPass123!',
        }),
      ).rejects.toThrow(ConflictException);
    });

    it('throws ConflictException for duplicate phone', async () => {
      prisma.user.findFirst.mockResolvedValue({ id: 'x', email: 'other@x.com', phoneNumber: '+38970123456' });

      await expect(
        service.register({
          firstName: 'Test',
          lastName: 'User',
          email: 'unique@chisto.mk',
          phoneNumber: '+38970123456',
          password: 'StrongPass123!',
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('citizenLogin', () => {
    it('authenticates user by phone number', async () => {
      prisma.user.findUnique.mockResolvedValue(mockUser);
      prisma.userSession.create.mockResolvedValue({});

      const result = await service.citizenLogin({
        phoneNumber: '+38970123456',
        password: 'StrongPass123!',
      });

      expect(result.accessToken).toBe('jwt-token');
      expect(result.user.phoneNumber).toBe('+38970123456');
      expect(result.user.avatarUrl).toBeNull();
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

      const result = await service.citizenLogin({
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
        service.citizenLogin({ phoneNumber: '+38999999999', password: 'any' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('rejects wrong password', async () => {
      prisma.user.findUnique.mockResolvedValue(mockUser);

      await expect(
        service.citizenLogin({ phoneNumber: '+38970123456', password: 'WrongPass!' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('rejects suspended user', async () => {
      prisma.user.findUnique.mockResolvedValue({ ...mockUser, status: UserStatus.SUSPENDED });

      await expect(
        service.citizenLogin({ phoneNumber: '+38970123456', password: 'StrongPass123!' }),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('adminLogin', () => {
    it('authenticates admin by email', async () => {
      prisma.user.findUnique.mockResolvedValue({ ...mockAdmin, totpSecret: null });
      prisma.userSession.create.mockResolvedValue({});

      const result = await service.adminLogin({
        email: 'admin@chisto.mk',
        password: 'StrongPass123!',
      });

      if (is2FAResponse(result)) throw new Error('Expected direct auth, not 2FA');
      expect(result.user.role).toBe(Role.ADMIN);
    });

    it('rejects non-admin role', async () => {
      prisma.user.findUnique.mockResolvedValue(mockUser);

      await expect(
        service.adminLogin({ email: 'test@chisto.mk', password: 'StrongPass123!' }),
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
        expiresAt: new Date(Date.now() + 86400000),
        revokedAt: null,
        user: mockUser,
      });
      prisma.userSession.update.mockResolvedValue({});
      prisma.userSession.create.mockResolvedValue({});

      const result = await service.refresh(fullToken);

      expect(result.accessToken).toBe('jwt-token');
      expect(result.refreshToken).toBeDefined();
      expect(result.refreshToken).toContain('.');
      expect(result.user.avatarUrl).toBeNull();
      expect(prisma.userSession.findUnique).toHaveBeenCalledWith({
        where: { tokenId },
        include: { user: true },
      });
      expect(prisma.userSession.update).toHaveBeenCalledWith({
        where: { id: 'session-1' },
        data: { revokedAt: expect.any(Date) },
      });
    });

    it('rejects refresh token without tokenId format', async () => {
      await expect(service.refresh('no-dot')).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('rejects invalid or unknown refresh token', async () => {
      prisma.userSession.findUnique.mockResolvedValue(null);
      await expect(
        service.refresh('tid123.wrongsecret'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('on reuse of a revoked refresh token with valid hash, revokes all user sessions and emits security event', async () => {
      const tokenId = 'reuse-tid';
      const fullToken = `${tokenId}.stillvalidsecret`;
      const hash = await bcrypt.hash(fullToken, 4);

      prisma.userSession.findUnique.mockResolvedValue({
        id: 'session-revoked',
        userId: 'user-1',
        tokenId,
        refreshTokenHash: hash,
        expiresAt: new Date(Date.now() + 86400000),
        revokedAt: new Date(),
        user: mockUser,
      });

      await expect(service.refresh(fullToken)).rejects.toThrow(UnauthorizedException);
      expect(prisma.userSession.updateMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { userId: 'user-1', revokedAt: null },
        }),
      );
      expect(eventEmitter.emit).toHaveBeenCalledWith(
        'security.refresh_token_reuse',
        expect.objectContaining({ userId: 'user-1' }),
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

      await service.logout(fullToken);

      expect(prisma.userSession.findUnique).toHaveBeenCalledWith({
        where: { tokenId },
      });
      expect(prisma.userSession.update).toHaveBeenCalledWith({
        where: { id: 'session-2' },
        data: { revokedAt: expect.any(Date) },
      });
    });

    it('does nothing if token has no dot', async () => {
      await service.logout('no-match');
      expect(prisma.userSession.findUnique).not.toHaveBeenCalled();
    });

    it('does nothing if token does not match any session', async () => {
      prisma.userSession.findUnique.mockResolvedValue(null);
      await service.logout('tid.nope');
      expect(prisma.userSession.update).not.toHaveBeenCalled();
    });
  });

  describe('avatar lifecycle', () => {
    it('returns signed avatar URL from me()', async () => {
      const reportsUpload = {
        signPrivateObjectKey: jest.fn().mockResolvedValue('https://signed/avatar'),
      };
      (service as any).reportsUploadService = reportsUpload;
      prisma.user.findUnique.mockResolvedValue({
        ...mockUser,
        totpSecret: null,
        avatarObjectKey: 'profile-avatars/user-1/a.webp',
      });

      const result = await service.me({
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
      (service as any).reportsUploadService = reportsUpload;
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        status: UserStatus.ACTIVE,
        avatarObjectKey: 'profile-avatars/user-1/old.webp',
      });
      const result = await service.uploadAvatar('user-1', {
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
