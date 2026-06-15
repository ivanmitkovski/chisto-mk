import { z } from "zod";

/** Anchor ids: lowercase kebab-case segments. */
const sectionIdSchema = z
  .string()
  .min(1)
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, "Section id must be kebab-case");

const INTERNAL_HREF = /^\/(privacy|data|terms|cookies|contact)(\/|$)|^\/help(\/[a-z0-9-]+)?$/;

const internalLinkBlockSchema = z
  .object({
    type: z.literal("internalLink"),
    href: z.string().min(1),
    label: z.string().min(1),
  })
  .superRefine((val, ctx) => {
    if (!INTERNAL_HREF.test(val.href)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: `internalLink href not allow-listed: ${val.href}`,
      });
    }
  });

export const helpContentBlockSchema = z.discriminatedUnion("type", [
  z.object({
    type: z.literal("paragraph"),
    text: z.string().min(1),
  }),
  z.object({
    type: z.literal("bullets"),
    title: z.string().optional(),
    items: z.array(z.string().min(1)).min(1),
  }),
  z.object({
    type: z.literal("callout"),
    variant: z.enum(["tip", "note"]),
    text: z.string().min(1),
  }),
  internalLinkBlockSchema,
]);

export type HelpContentBlock = z.infer<typeof helpContentBlockSchema>;

export const helpArticleSectionSchema = z.object({
  id: sectionIdSchema,
  title: z.string().min(1),
  blocks: z.array(helpContentBlockSchema).min(1).max(24),
});

const optionalIsoDateTime = z
  .string()
  .refine((s) => !Number.isNaN(Date.parse(s)), { message: "Expected parseable ISO-8601 date/time" })
  .optional();

export const helpArticleMessageSchema = z.object({
  cardTitle: z.string().min(1),
  cardSummary: z.string().min(1),
  title: z.string().min(1),
  lastUpdated: z.string().min(1),
  lastReviewed: z.string().min(1),
  /** Machine-readable dates for structured data when provided (editorial). */
  datePublished: optionalIsoDateTime,
  dateModified: optionalIsoDateTime,
  sections: z.array(helpArticleSectionSchema).min(3).max(12),
});

export type HelpArticleMessage = z.infer<typeof helpArticleMessageSchema>;

const articlesRecordSchema = z.record(z.string(), helpArticleMessageSchema);

/**
 * Validates `helpCentre.articles` for one locale. Throws [ZodError] on failure.
 */
export function parseHelpCentreArticles(articles: unknown): Record<string, HelpArticleMessage> {
  return articlesRecordSchema.parse(articles);
}

/**
 * Validates every expected slug exists and parses; returns Zod issues as strings for tests.
 */
export function validateHelpArticlesForSlugs(
  articles: unknown,
  expectedSlugs: readonly string[],
): { ok: true; data: Record<string, HelpArticleMessage> } | { ok: false; errors: string[] } {
  const parsed = articlesRecordSchema.safeParse(articles);
  if (!parsed.success) {
    return {
      ok: false,
      errors: parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`),
    };
  }
  const data = parsed.data;
  const missing = expectedSlugs.filter((s) => data[s] == null);
  if (missing.length > 0) {
    return { ok: false, errors: [`Missing article keys: ${missing.join(", ")}`] };
  }
  return { ok: true, data };
}
