import { appendFile, mkdir, readFile } from "node:fs/promises";
import path from "node:path";
import { getSupabaseAdmin } from "@/lib/supabase-admin";

const DATA_DIR = path.join(process.cwd(), "data");
const LIST_FILE = path.join(DATA_DIR, "notify-subscribers.jsonl");

export type NotifySubscriberRow = {
  email: string;
  locale: string;
  createdAt: string;
};

async function readRowsFromFile(): Promise<NotifySubscriberRow[]> {
  let raw: string;
  try {
    raw = await readFile(LIST_FILE, "utf8");
  } catch (e) {
    const code = e && typeof e === "object" && "code" in e ? (e as NodeJS.ErrnoException).code : undefined;
    if (code === "ENOENT") return [];
    throw e;
  }
  const out: NotifySubscriberRow[] = [];
  for (const line of raw.split("\n")) {
    if (!line.trim()) continue;
    try {
      const o = JSON.parse(line) as NotifySubscriberRow;
      if (typeof o.email === "string" && o.email) {
        out.push({
          email: o.email.toLowerCase(),
          locale: typeof o.locale === "string" ? o.locale : "",
          createdAt: typeof o.createdAt === "string" ? o.createdAt : "",
        });
      }
    } catch {
      /* skip bad line */
    }
  }
  return out;
}

async function tryAddSubscriberFile(
  email: string,
  locale: string,
): Promise<"ok" | "duplicate" | "error"> {
  const normalized = email.trim().toLowerCase();
  try {
    await mkdir(DATA_DIR, { recursive: true });
    const rows = await readRowsFromFile();
    if (rows.some((r) => r.email === normalized)) {
      return "duplicate";
    }
    const row: NotifySubscriberRow = {
      email: normalized,
      locale,
      createdAt: new Date().toISOString(),
    };
    await appendFile(LIST_FILE, `${JSON.stringify(row)}\n`, "utf8");
    return "ok";
  } catch (e) {
    console.error("[notify-subscribers-store] file", e);
    return "error";
  }
}

async function tryAddSubscriberSupabase(
  email: string,
  locale: string,
): Promise<"ok" | "duplicate" | "error"> {
  const supabase = getSupabaseAdmin();
  if (!supabase) {
    return "error";
  }
  const normalized = email.trim().toLowerCase();
  const { error } = await supabase.from("notify_subscribers").insert({
    email: normalized,
    locale,
  });

  if (!error) {
    return "ok";
  }

  const code = "code" in error ? String((error as { code?: string }).code) : "";
  const msg = error.message ?? "";
  if (code === "23505" || msg.includes("duplicate key") || msg.includes("unique")) {
    return "duplicate";
  }

  console.error("[notify-subscribers-store] supabase", error);
  return "error";
}

/**
 * Append a row if the email is not already present.
 * Uses Supabase when `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` are set; otherwise local JSONL file.
 */
export async function tryAddSubscriber(
  email: string,
  locale: string,
): Promise<"ok" | "duplicate" | "error"> {
  if (getSupabaseAdmin()) {
    return tryAddSubscriberSupabase(email, locale);
  }
  return tryAddSubscriberFile(email, locale);
}
