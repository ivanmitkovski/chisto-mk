import { Role } from '../prisma-client';

export const ADMIN_PANEL_ROLES: Role[] = [Role.SUPPORT, Role.ADMIN, Role.SUPER_ADMIN];

export const ADMIN_WRITE_ROLES: Role[] = [Role.ADMIN, Role.SUPER_ADMIN];

export const SUPER_ADMIN_ROLES: Role[] = [Role.SUPER_ADMIN];
