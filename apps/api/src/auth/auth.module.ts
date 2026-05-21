import { Global, Logger, Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthSessionController } from './auth-session.controller';
import { AuthPasswordController } from './auth-password.controller';
import { AuthMfaController } from './auth-mfa.controller';
import { AuthProfileController } from './auth-profile.controller';
import { AuthProfileIdentifierController } from './auth-profile-identifier.controller';
import { AuthProfilePrivacyController } from './auth-profile-privacy.controller';
import { AuthAdminController } from './auth-admin.controller';
import { AUTH_ENV_RUNTIME, loadAuthEnvRuntime } from './auth-env.config';
import { AuthSessionService } from './auth-session.service';
import { AuthRegistrationService } from './auth-registration.service';
import { AuthAdminLoginService } from './auth-admin-login.service';
import { AuthMfaService } from './auth-mfa.service';
import { AuthProfileService } from './auth-profile.service';
import { AuthProfileReadService } from './auth-profile-read.service';
import { AuthProfileAvatarService } from './auth-profile-avatar.service';
import { AuthCredentialService } from './auth-credential.service';
import { AuthOtpService } from './auth-otp.service';
import { AuthLoginService } from './auth-login.service';
import { PasswordResetService } from './password-reset.service';
import { PhoneVerifiedGuard } from './phone-verified.guard';
import { JwtAuthGuard } from './jwt-auth.guard';
import { JwtStrategy } from './jwt.strategy';
import { OptionalJwtAuthGuard } from './optional-jwt-auth.guard';
import { OrganizerCertificationService } from './organizer-certification.service';
import { RolesGuard } from './roles.guard';
import { EmailModule } from '../email/email.module';
import { OtpModule } from '../otp/otp.module';
import { AuditModule } from '../audit/audit.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { GamificationModule } from '../gamification/gamification.module';
import { UserAuthSnapshotCacheService } from './user-auth-snapshot-cache.service';
import { AuthSessionRevocationService } from './auth-session-revocation.service';
import { SecurityEventsListener } from './security-events.listener';
import { AccountErasureService } from './account-erasure.service';
import { AccountErasureCronService } from './account-erasure-cron.service';
import { AuthIdentifierChangeService } from './auth-identifier-change.service';
import { UserDsarExportService } from './user-dsar-export.service';
import { AuthIdentifierThrottleService } from './auth-identifier-throttle.service';

/** Global so JwtStrategy, JwtAuthGuard, and RolesGuard resolve in every feature module without duplicate imports. */
@Global()
@Module({
  imports: [
    ConfigModule,
    AuditModule,
    ReportsUploadModule,
    GamificationModule,
    EmailModule,
    OtpModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const secret = configService.get<string>('JWT_SECRET');
        if (!secret) {
          const logger = new Logger('AuthModule');
          logger.error('JWT_SECRET is not configured (validateEnv should have caught this). Exiting.');
          process.exit(1);
        }

        return { secret };
      },
    }),
  ],
  controllers: [
    AuthSessionController,
    AuthPasswordController,
    AuthMfaController,
    AuthProfileController,
    AuthProfileIdentifierController,
    AuthProfilePrivacyController,
    AuthAdminController,
  ],
  providers: [
    {
      provide: AUTH_ENV_RUNTIME,
      useFactory: (configService: ConfigService) => loadAuthEnvRuntime(configService),
      inject: [ConfigService],
    },
    UserAuthSnapshotCacheService,
    AuthSessionRevocationService,
    SecurityEventsListener,
    AccountErasureService,
    AccountErasureCronService,
    AuthIdentifierChangeService,
    UserDsarExportService,
    AuthIdentifierThrottleService,
    AuthSessionService,
    AuthRegistrationService,
    AuthLoginService,
    AuthOtpService,
    PasswordResetService,
    AuthAdminLoginService,
    AuthMfaService,
    AuthProfileReadService,
    AuthProfileAvatarService,
    AuthProfileService,
    AuthCredentialService,
    PhoneVerifiedGuard,
    JwtStrategy,
    JwtAuthGuard,
    RolesGuard,
    OptionalJwtAuthGuard,
    OrganizerCertificationService,
  ],
  exports: [
    JwtAuthGuard,
    RolesGuard,
    OptionalJwtAuthGuard,
    PhoneVerifiedGuard,
    AuditModule,
    AuthSessionRevocationService,
    UserAuthSnapshotCacheService,
    AuthIdentifierThrottleService,
  ],
})
export class AuthModule {}
