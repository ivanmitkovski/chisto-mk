import { z } from 'zod';
import { ReportStatus, Role, SiteStatus } from '../../prisma-client';

const authenticatedUserSchema = z.object({
  userId: z.string(),
  email: z.string(),
  phoneNumber: z.string(),
  role: z.nativeEnum(Role),
  sessionId: z.string().optional(),
});

const siteStatusEventSchema = z.object({
  id: z.string(),
  status: z.nativeEnum(SiteStatus),
  latitude: z.number(),
  longitude: z.number(),
  updatedAt: z.string(),
});

export const mergeDuplicateSideEffectPayloadSchema = z.object({
  moderator: authenticatedUserSchema,
  primaryReport: z.object({
    id: z.string(),
    siteId: z.string(),
    reporterId: z.string().nullable(),
    reportNumber: z.string().nullable(),
    createdAt: z.string(),
    mediaUrls: z.array(z.string()),
  }),
  selectedChildIds: z.array(z.string()),
  selectedChildren: z.array(
    z.object({
      id: z.string(),
      reporterId: z.string().nullable(),
    }),
  ),
  plannedNewCoReporterIds: z.array(z.string()),
  duplicateMediaUrls: z.array(z.string()),
  siteStatusEvent: siteStatusEventSchema.nullable(),
});

export const moderationStatusSideEffectPayloadSchema = z.object({
  moderatorUserId: z.string(),
  reportId: z.string(),
  fromStatus: z.nativeEnum(ReportStatus),
  toStatus: z.nativeEnum(ReportStatus),
  reason: z.string().nullable(),
  siteId: z.string(),
  reporterId: z.string().nullable(),
  coReporterUserIds: z.array(z.string()),
  siteStatusEvent: siteStatusEventSchema.nullable(),
});

export type MergeDuplicateSideEffectPayload = z.infer<
  typeof mergeDuplicateSideEffectPayloadSchema
>;

export type ModerationStatusSideEffectPayload = z.infer<
  typeof moderationStatusSideEffectPayloadSchema
>;

export function parseMergeDuplicateSideEffectPayload(
  value: unknown,
): MergeDuplicateSideEffectPayload {
  return mergeDuplicateSideEffectPayloadSchema.parse(value);
}

export function parseModerationStatusSideEffectPayload(
  value: unknown,
): ModerationStatusSideEffectPayload {
  return moderationStatusSideEffectPayloadSchema.parse(value);
}
