import { Module } from '@nestjs/common';
import { UsersAvatarService } from './users-avatar.service';

@Module({
  imports: [],
  providers: [UsersAvatarService],
  exports: [UsersAvatarService],
})
export class UsersAvatarModule {}
