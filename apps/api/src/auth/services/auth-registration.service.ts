import { ConflictException, Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EventEmitter2 } from '@nestjs/event-emitter';
import * as bcrypt from 'bcrypt';
import { Role } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { RegisterDto } from '../dto/register.dto';
import { RegisterResponse } from '../types/register-response.type';
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from '../constants/auth-env.config';
import { AuthOtpService } from './auth-otp.service';
import { OTP_EXPIRES_SECONDS } from '../constants/auth.constants';
import {
  assertRegisterTermsAcceptance,
  resolveTermsVersionFromEnv,
} from '../util/terms-consent.util';

@Injectable()
export class AuthRegistrationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
    private readonly authOtp: AuthOtpService,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
    private readonly configService: ConfigService,
  ) {}

  async register(dto: RegisterDto, acceptLanguage?: string): Promise<RegisterResponse> {
    const currentTermsVersion = resolveTermsVersionFromEnv(
      this.configService.get<string>('TERMS_VERSION'),
    );
    assertRegisterTermsAcceptance(dto, currentTermsVersion);
    const firstName = dto.firstName.trim();
    const lastName = dto.lastName.trim();
    const email = dto.email.toLowerCase().trim();
    const phoneNumber = dto.phoneNumber.trim();

    const existingUser = await this.prisma.user.findFirst({
      where: {
        OR: [{ email }, { phoneNumber }],
      },
      select: { id: true, email: true, phoneNumber: true },
    });

    if (existingUser) {
      throw new ConflictException({
        code: 'REGISTRATION_CONFLICT',
        message: 'An account with this email or phone number already exists',
      });
    }

    const passwordHash = await bcrypt.hash(dto.password, this.env.saltRounds);
    const user = await this.prisma.user.create({
      data: {
        firstName,
        lastName,
        email,
        phoneNumber,
        passwordHash,
        role: Role.USER,
        isPhoneVerified: false,
        termsAcceptedAt: new Date(dto.termsAcceptedAt),
        termsVersion: dto.termsVersion.trim(),
        privacyAcceptedAt: new Date(dto.privacyAcceptedAt ?? dto.termsAcceptedAt),
      },
    });

    this.eventEmitter.emit('user.created', { userId: user.id });

    const otpResult = await this.authOtp.sendPhoneVerificationOtp(phoneNumber, acceptLanguage);

    return {
      userId: user.id,
      phoneNumber: user.phoneNumber,
      requiresPhoneVerification: true,
      otpExpiresIn: OTP_EXPIRES_SECONDS,
      ...(otpResult.devCode != null ? { devCode: otpResult.devCode } : {}),
    };
  }
}
