import { Module } from '@nestjs/common';
import { UsersAvatarModule } from '../users/users-avatar.module';
import { ReportsUploadService } from './reports-upload.service';

@Module({
  imports: [UsersAvatarModule],
  providers: [ReportsUploadService],
  exports: [ReportsUploadService],
})
export class ReportsUploadModule {}
