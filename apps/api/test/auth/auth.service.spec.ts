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
    },
    userSession: {
      create: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
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

describe('AuthService', () => {
  let service: AuthService;
  let prisma: ReturnType<typeof makePrisma>;
  let jwt: ReturnType<typeof makeJwt>;

  beforeEach(async () => {
    prisma = makePrisma();
    jwt = makeJwt();
    const config = makeConfig();
    const otpSender = makeOtpSender();
    mockUser.passwordHash = await bcrypt.hash('StrongPass123!', 4);
    mockAdmin.passwordHash = mockUser.passwordHash;

    const otpService = makeOtpService();
    const audit = makeAudit();
    const eventEmitter = makeEventEmitter();
    service = new AuthService(
      prisma as any,
      jwt as unknown as JwtService,
      otpService as any,
      config as unknown as ConfigService,
      otpSender as any,
      audit as any,
      eventEmitter as any,
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
});
