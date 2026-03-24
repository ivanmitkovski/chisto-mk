import { BadRequestException, ForbiddenException, Injectable } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { AuditService } from '../audit/audit.service';
import { Role } from '../prisma-client';
import { PatchSystemConfigDto } from './dto/patch-system-config.dto';

const ALLOWED_KEYS = [
  'active_environment',
  'api_url_dev',
  'api_url_staging',
  'api_url_prod',
  'maintenance_mode',
] as const;

const ACTIVE_ENVIRONMENT_VALUES = ['dev', 'staging', 'prod'] as const;

const URL_KEYS = ['api_url_dev', 'api_url_staging', 'api_url_prod'] as const;

function validateKey(key: string): void {
  if (!ALLOWED_KEYS.includes(key as (typeof ALLOWED_KEYS)[number])) {
    throw new BadRequestException({
      code: 'CONFIG_KEY_NOT_ALLOWED',
      message: `Configuration key '${key}' is not in the allowlist`,
      details: { allowedKeys: [...ALLOWED_KEYS] },
    });
  }
}

function validateValue(key: string, value: string): void {
  if (key === 'active_environment') {
    if (!ACTIVE_ENVIRONMENT_VALUES.includes(value as (typeof ACTIVE_ENVIRONMENT_VALUES)[number])) {
      throw new BadRequestException({
        code: 'INVALID_ACTIVE_ENVIRONMENT',
        message: `active_environment must be one of: ${ACTIVE_ENVIRONMENT_VALUES.join(', ')}`,
      });
    }
  }
  if (URL_KEYS.includes(key as (typeof URL_KEYS)[number]) && value) {
    try {
      new URL(value);
    } catch {
      throw new BadRequestException({
        code: 'INVALID_URL',
        message: `Value for ${key} must be a valid URL`,
      });
    }
  }
}

const DEFAULT_KEYS: Array<{ key: string; value: string }> = [
  { key: 'active_environment', value: 'dev' },
  { key: 'api_url_dev', value: 'https://api-dev.chisto.mk' },
  { key: 'api_url_staging', value: 'https://api-staging.chisto.mk' },
  { key: 'api_url_prod', value: 'https://api.chisto.mk' },
];

@Injectable()
export class SystemConfigService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async ensureDefaults(): Promise<void> {
    for (const row of DEFAULT_KEYS) {
      await this.prisma.systemConfig.upsert({
        where: { key: row.key },
        create: { key: row.key, value: row.value },
        update: {},
      });
    }
  }

  async getAll(): Promise<
    Array<{
      key: string;
      value: string;
      updatedAt: string;
    }>
  > {
    await this.ensureDefaults();
    const rows = await this.prisma.systemConfig.findMany({
      orderBy: { key: 'asc' },
    });
    return rows.map((r) => ({
      key: r.key,
      value: r.value,
      updatedAt: r.updatedAt.toISOString(),
    }));
  }

  async getPublic(): Promise<{
    activeEnvironment: string;
    apiUrls: { dev: string; staging: string; prod: string };
  }> {
    await this.ensureDefaults();
    const rows = await this.prisma.systemConfig.findMany({
      where: {
        key: {
          in: ['active_environment', 'api_url_dev', 'api_url_staging', 'api_url_prod'],
        },
      },
    });
    const map = Object.fromEntries(rows.map((r) => [r.key, r.value]));
    return {
      activeEnvironment: map.active_environment ?? 'dev',
      apiUrls: {
        dev: map.api_url_dev ?? '',
        staging: map.api_url_staging ?? '',
        prod: map.api_url_prod ?? '',
      },
    };
  }

  validate(dto: PatchSystemConfigDto): { valid: boolean; errors?: Array<{ key: string; message: string }> } {
    const errors: Array<{ key: string; message: string }> = [];
    for (const entry of dto.entries) {
      try {
        validateKey(entry.key);
      } catch (e) {
        const res = e instanceof BadRequestException ? (e.getResponse() as { message?: string }) : null;
        errors.push({ key: entry.key, message: res?.message ?? 'Key not allowed' });
        continue;
      }
      try {
        validateValue(entry.key, entry.value);
      } catch (e) {
        const res = e instanceof BadRequestException ? (e.getResponse() as { message?: string }) : null;
        errors.push({ key: entry.key, message: res?.message ?? 'Invalid value' });
      }
    }
    return errors.length === 0 ? { valid: true } : { valid: false, errors };
  }

  async patch(
    dto: PatchSystemConfigDto,
    actor: AuthenticatedUser,
  ): Promise<{ updated: number }> {
    if (actor.role !== Role.SUPER_ADMIN) {
      throw new ForbiddenException({
        code: 'FORBIDDEN',
        message: 'Only a super admin can change system configuration',
      });
    }

    const changes: Array<{ key: string; before: string; after: string }> = [];
    let updated = 0;

    for (const entry of dto.entries) {
      validateKey(entry.key);
      validateValue(entry.key, entry.value);

      const existing = await this.prisma.systemConfig.findUnique({
        where: { key: entry.key },
      });

      await this.prisma.systemConfig.upsert({
        where: { key: entry.key },
        create: { key: entry.key, value: entry.value },
        update: { value: entry.value },
      });
      changes.push({
        key: entry.key,
        before: existing?.value ?? '(none)',
        after: entry.value,
      });
      updated += 1;
    }

    await this.audit.log({
      actorId: actor.userId,
      action: 'SYSTEM_CONFIG_UPDATED',
      resourceType: 'SystemConfig',
      metadata: {
        changes,
      } as Prisma.InputJsonValue,
    });

    return { updated };
  }
}
