import { ConflictException, Inject, Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import * as bcrypt from 'bcrypt';
import { Role } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { RegisterResponse } from './types/register-response.type';
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from './auth-env.config';
import { AuthOtpService } from './auth-otp.service';
import { OTP_EXPIRES_SECONDS } from './auth.constants';

@Injectable()
export class AuthRegistrationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
    private readonly authOtp: AuthOtpService,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
  ) {}

  async register(dto: RegisterDto, acceptLanguage?: string): Promise<RegisterResponse> {
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
      if (existingUser.email === email) {
        throw new ConflictException({
          code: 'EMAIL_ALREADY_REGISTERED',
          message: 'Email is already registered',
        });
      }
      throw new ConflictException({
        code: 'PHONE_ALREADY_REGISTERED',
        message: 'Phone number is already registered',
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
      },
    });

    this.eventEmitter.emit('user.created', { userId: user.id });

    await this.authOtp.sendPhoneVerificationOtp(phoneNumber, acceptLanguage);

    return {
      userId: user.id,
      phoneNumber: user.phoneNumber,
      requiresPhoneVerification: true,
      otpExpiresIn: OTP_EXPIRES_SECONDS,
    };
  }
}
