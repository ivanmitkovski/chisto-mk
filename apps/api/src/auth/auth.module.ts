import { Global, Logger, Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthSessionController } from './auth-session.controller';
import { AuthPasswordController } from './auth-password.controller';
import { AuthMfaController } from './auth-mfa.controller';
import { AuthProfileController } from './auth-profile.controller';
import { AUTH_ENV_RUNTIME, loadAuthEnvRuntime } from './auth-env.config';
import { AuthSessionService } from './auth-session.service';
import { AuthRegistrationService } from './auth-registration.service';
import { AuthAdminLoginService } from './auth-admin-login.service';
import { AuthMfaService } from './auth-mfa.service';
import { AuthProfileService } from './auth-profile.service';
import { AuthCredentialService } from './auth-credential.service';
import { JwtAuthGuard } from './jwt-auth.guard';
import { JwtStrategy } from './jwt.strategy';
import { OptionalJwtAuthGuard } from './optional-jwt-auth.guard';
import { OrganizerCertificationService } from './organizer-certification.service';
import { RolesGuard } from './roles.guard';
import { OtpModule } from '../otp/otp.module';
import { AuditModule } from '../audit/audit.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { GamificationModule } from '../gamification/gamification.module';

/** Global so JwtStrategy, JwtAuthGuard, and RolesGuard resolve in every feature module without duplicate imports. */
@Global()
@Module({
  imports: [
    ConfigModule,
    AuditModule,
    ReportsUploadModule,
    GamificationModule,
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
  ],
  providers: [
    {
      provide: AUTH_ENV_RUNTIME,
      useFactory: (configService: ConfigService) => loadAuthEnvRuntime(configService),
      inject: [ConfigService],
    },
    AuthSessionService,
    AuthRegistrationService,
    AuthAdminLoginService,
    AuthMfaService,
    AuthProfileService,
    AuthCredentialService,
    JwtStrategy,
    JwtAuthGuard,
    RolesGuard,
    OptionalJwtAuthGuard,
    OrganizerCertificationService,
  ],
  // Re-export AuditModule so RolesGuard (AuditService) resolves in every feature module that uses @UseGuards(RolesGuard).
  exports: [JwtAuthGuard, RolesGuard, OptionalJwtAuthGuard, AuditModule],
})
export class AuthModule {}
