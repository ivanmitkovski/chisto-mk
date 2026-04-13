import { Global, Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigService } from '@nestjs/config';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtStrategy } from './jwt.strategy';
import { RolesGuard } from './roles.guard';
import { OtpModule } from '../otp/otp.module';
import { AuditModule } from '../audit/audit.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { GamificationModule } from '../gamification/gamification.module';

/** Global so JwtStrategy, JwtAuthGuard, and RolesGuard resolve in every feature module without duplicate imports. */
@Global()
@Module({
  imports: [
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
          throw new Error('JWT_SECRET is not configured');
        }

        return { secret };
      },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, RolesGuard],
  exports: [AuthService, RolesGuard],
})
export class AuthModule {}
