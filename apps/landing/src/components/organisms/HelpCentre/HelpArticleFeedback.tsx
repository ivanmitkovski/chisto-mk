"use client";

import { useState } from "react";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/routing";
import { trackHelpEvent } from "@/lib/analytics/track-help";
import type { HelpArticleSlug } from "@/lib/help/help-catalog";

type Phase = "ask" | "no_followup" | "thanks";

const REASON_MAX = 500;

export function HelpArticleFeedback({ slug }: { slug: HelpArticleSlug }) {
  const t = useTranslations("helpCentre.common");
  const [phase, setPhase] = useState<Phase>("ask");
  const [reason, setReason] = useState("");
  const [terminalLocked, setTerminalLocked] = useState(false);

  if (phase === "thanks") {
    return (
      <p className="text-sm text-gray-600" role="status">
        {t("feedbackThanks")}
      </p>
    );
  }

  if (phase === "no_followup") {
    return (
      <div className="rounded-2xl border border-gray-200/90 bg-white/90 p-5 shadow-sm md:p-6">
        <p className="text-sm font-semibold text-gray-900">{t("feedbackNoFollowupTitle")}</p>
        <p className="mt-2 text-sm text-gray-600">{t("feedbackNoFollowupHint")}</p>
        <label htmlFor="help-feedback-reason" className="sr-only">
          {t("feedbackReasonLabel")}
        </label>
        <textarea
          id="help-feedback-reason"
          value={reason}
          maxLength={REASON_MAX}
          rows={3}
          onChange={(e) => setReason(e.target.value.slice(0, REASON_MAX))}
          placeholder={t("feedbackReasonPlaceholder")}
          className="mt-4 w-full resize-y rounded-xl border border-gray-200/90 bg-white px-3 py-2 text-sm text-gray-900 shadow-inner outline-none ring-primary/20 focus:border-primary/35 focus:ring-2"
        />
        <p className="mt-4 text-sm text-gray-600">
          {t("feedbackContactIntro")}{" "}
          <Link href="/contact" className="font-semibold text-primary underline-offset-2 hover:underline">
            {t("feedbackContactLink")}
          </Link>
        </p>
        <div className="mt-5 flex flex-wrap gap-3">
          <button
            type="button"
            disabled={terminalLocked}
            className="rounded-full border border-gray-200 bg-white px-5 py-2 text-sm font-semibold text-gray-800 shadow-sm transition-colors hover:border-primary/35 hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50"
            onClick={() => {
              if (terminalLocked) return;
              setTerminalLocked(true);
              const trimmed = reason.trim();
              trackHelpEvent("help_feedback_no", {
                slug,
                hasReason: trimmed.length > 0,
                reasonChars: trimmed.length,
              });
              setPhase("thanks");
            }}
          >
            {t("feedbackSubmit")}
          </button>
          <button
            type="button"
            disabled={terminalLocked}
            className="rounded-full border border-transparent px-4 py-2 text-sm font-semibold text-gray-600 underline-offset-2 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50"
            onClick={() => {
              if (terminalLocked) return;
              setTerminalLocked(true);
              trackHelpEvent("help_feedback_no", { slug, hasReason: false, reasonChars: 0 });
              setPhase("thanks");
            }}
          >
            {t("feedbackSkipDetails")}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="rounded-2xl border border-gray-200/90 bg-white/90 p-5 shadow-sm md:p-6">
      <p className="text-sm font-semibold text-gray-900">{t("feedbackPrompt")}</p>
      <div className="mt-4 flex flex-wrap gap-3">
        <button
          type="button"
          disabled={terminalLocked}
          className="rounded-full border border-gray-200 bg-white px-5 py-2 text-sm font-semibold text-gray-800 shadow-sm transition-colors hover:border-primary/35 hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50"
          onClick={() => {
            if (terminalLocked) return;
            setTerminalLocked(true);
            trackHelpEvent("help_feedback_yes", { slug });
            setPhase("thanks");
          }}
        >
          {t("feedbackYes")}
        </button>
        <button
          type="button"
          disabled={terminalLocked}
          className="rounded-full border border-gray-200 bg-white px-5 py-2 text-sm font-semibold text-gray-800 shadow-sm transition-colors hover:border-primary/35 hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50"
          onClick={() => {
            if (terminalLocked) return;
            setPhase("no_followup");
          }}
        >
          {t("feedbackNo")}
        </button>
      </div>
    </div>
  );
}
