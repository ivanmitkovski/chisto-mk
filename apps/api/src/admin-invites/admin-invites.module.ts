import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { EmailModule } from '../email/email.module';
import { AuditModule } from '../audit/audit.module';
import { AdminInvitesController } from './controllers/admin-invites.controller';
import { AdminInviteAcceptController } from './controllers/admin-invite-accept.controller';
import { AdminInvitesService } from './services/admin-invites.service';
import { AdminInviteAcceptService } from './services/admin-invite-accept.service';

@Module({
  imports: [AuthModule, EmailModule, AuditModule],
  controllers: [AdminInviteAcceptController, AdminInvitesController],
  providers: [AdminInvitesService, AdminInviteAcceptService],
})
export class AdminInvitesModule {}
