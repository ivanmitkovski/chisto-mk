import { SetMetadata } from '@nestjs/common';
import type { AdminPermission } from '../constants/admin-permissions';

export const PERMISSIONS_KEY = 'permissions';

export const RequirePermission = (...permissions: AdminPermission[]) =>
  SetMetadata(PERMISSIONS_KEY, permissions);
