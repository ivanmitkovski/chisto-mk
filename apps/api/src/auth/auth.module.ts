import { Global, Logger, Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthSessionController } from './controllers/auth-session.controller';
import { AuthPasswordController } from './controllers/auth-password.controller';
import { AuthMfaController } from './controllers/auth-mfa.controller';
import { AuthProfileController } from './controllers/auth-profile.controller';
import { AuthProfileIdentifierController } from './controllers/auth-profile-identifier.controller';
import { AuthProfilePrivacyController } from './controllers/auth-profile-privacy.controller';
import { AuthAdminController } from './controllers/auth-admin.controller';
import { AUTH_ENV_RUNTIME, loadAuthEnvRuntime } from './constants/auth-env.config';
import { AuthSessionService } from './services/auth-session.service';
import { AuthRegistrationService } from './services/auth-registration.service';
import { AuthAdminLoginService } from './services/auth-admin-login.service';
import { AuthMfaService } from './services/auth-mfa.service';
import { AuthProfileService } from './services/auth-profile.service';
import { AuthProfileReadService } from './services/auth-profile-read.service';
import { AuthProfileAvatarService } from './services/auth-profile-avatar.service';
import { AuthCredentialService } from './services/auth-credential.service';
import { AuthOtpService } from './services/auth-otp.service';
import { AuthLoginService } from './services/auth-login.service';
import { PasswordResetService } from './services/password-reset.service';
import { PasswordResetCompletionService } from './services/password-reset-completion.service';
import { PasswordResetSmsFlowService } from './services/password-reset-sms-flow.service';
import { PasswordResetEmailFlowService } from './services/password-reset-email-flow.service';
import { RefreshTokenRotationService } from './services/refresh-token-rotation.service';
import { PhoneVerifiedGuard } from './guards/phone-verified.guard';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { JwtStrategy } from './strategies/jwt.strategy';
import { OptionalJwtAuthGuard } from './guards/optional-jwt-auth.guard';
import { OrganizerCertificationService } from './services/organizer-certification.service';
import { PermissionsGuard } from './guards/permissions.guard';
import { RolesGuard } from './guards/roles.guard';
import { EmailModule } from '../email/email.module';
import { OtpModule } from '../otp/otp.module';
import { AuditModule } from '../audit/audit.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { GamificationModule } from '../gamification/gamification.module';
import { SiteCommentsCountModule } from '../sites/site-comments-count.module';
import { UserAuthSnapshotCacheService } from './services/user-auth-snapshot-cache.service';
import { AuthSessionRevocationService } from './services/auth-session-revocation.service';
import { SecurityEventsListener } from './listeners/security-events.listener';
import { AccountErasureService } from './services/account-erasure.service';
import { AccountErasureCronService } from './services/account-erasure-cron.service';
import { AuthIdentifierChangeService } from './services/auth-identifier-change.service';
import { UserDsarExportService } from './services/user-dsar-export.service';
import { AuthIdentifierThrottleService } from './services/auth-identifier-throttle.service';
import { AuthRefreshReplayCacheService } from './services/auth-refresh-replay-cache.service';

/** Global so JwtStrategy, JwtAuthGuard, and RolesGuard resolve in every feature module without duplicate imports. */
@Global()
@Module({
  imports: [
    ConfigModule,
    AuditModule,
    ReportsUploadModule,
    GamificationModule,
    SiteCommentsCountModule,
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
    AuthRefreshReplayCacheService,
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
    PasswordResetCompletionService,
    PasswordResetSmsFlowService,
    PasswordResetEmailFlowService,
    RefreshTokenRotationService,
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
    PermissionsGuard,
    OptionalJwtAuthGuard,
    OrganizerCertificationService,
  ],
  exports: [
    JwtAuthGuard,
    RolesGuard,
    PermissionsGuard,
    OptionalJwtAuthGuard,
    PhoneVerifiedGuard,
    AuditModule,
    AUTH_ENV_RUNTIME,
    AccountErasureService,
    AuthSessionRevocationService,
    UserAuthSnapshotCacheService,
    AuthIdentifierThrottleService,
    AuthSessionService,
  ],
})
export class AuthModule {}
