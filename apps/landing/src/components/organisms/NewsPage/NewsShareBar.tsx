"use client";

import { useEffect, useState } from "react";
import { Check, Link2, Share2 } from "lucide-react";
import { trackNewsEvent } from "@/lib/analytics/track-news";
import { cn } from "@/lib/utils/cn";

export type NewsShareBarCopy = {
  copyLink: string;
  copyLinkAria: string;
  copied: string;
  copyLinkFailed: string;
  share: string;
  shareAria: string;
};

type NewsShareBarProps = {
  title: string;
  excerpt: string;
  copy: NewsShareBarCopy;
  variant?: "default" | "compact";
  className?: string;
};

export function NewsShareBar({
  title,
  excerpt,
  copy,
  variant = "default",
  className,
}: NewsShareBarProps) {
  const [copied, setCopied] = useState(false);
  const [copyFailed, setCopyFailed] = useState(false);
  // Detect Web Share after mount — navigator.share differs between SSR and client.
  const [canShare, setCanShare] = useState(false);

  useEffect(() => {
    setCanShare(typeof navigator.share === "function");
  }, []);

  async function onCopyLink() {
    setCopyFailed(false);
    try {
      await navigator.clipboard.writeText(window.location.href);
      setCopied(true);
      trackNewsEvent("news_share_copy_link");
      window.setTimeout(() => setCopied(false), 2000);
    } catch {
      setCopied(false);
      setCopyFailed(true);
      window.setTimeout(() => setCopyFailed(false), 3000);
    }
  }

  async function onShare() {
    if (typeof navigator.share !== "function") return;
    try {
      await navigator.share({
        title,
        text: excerpt,
        url: window.location.href,
      });
      trackNewsEvent("news_share_native");
    } catch {
      // User dismissed share sheet or share failed.
    }
  }

  const compact = variant === "compact";

  return (
    <div
      className={cn(
        "flex flex-wrap items-center gap-3 print:hidden",
        compact ? "mt-0" : "mt-8",
        className,
      )}
    >
      <button
        type="button"
        onClick={onCopyLink}
        aria-label={copied ? copy.copied : copy.copyLinkAria}
        className={cn(
          "inline-flex items-center gap-2 rounded-full border border-gray-200/90 bg-white/90 font-semibold text-gray-700 shadow-sm transition-[border-color,box-shadow,color]",
          "hover:border-primary/25 hover:text-gray-900 hover:shadow-md",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2",
          compact ? "min-h-9 px-3 py-1.5 text-xs" : "min-h-10 px-4 py-2 text-sm",
          copied && "border-emerald-200/90 text-emerald-700",
        )}
      >
        {copied ? (
          <Check className="h-4 w-4 shrink-0" strokeWidth={2.25} aria-hidden />
        ) : (
          <Link2 className="h-4 w-4 shrink-0" strokeWidth={2} aria-hidden />
        )}
        <span>{copied ? copy.copied : copy.copyLink}</span>
      </button>

      <p className="sr-only" role="status" aria-live="polite">
        {copied ? copy.copied : copyFailed ? copy.copyLinkFailed : ""}
      </p>

      {copyFailed ? (
        <p className="text-sm text-red-600" role="status">
          {copy.copyLinkFailed}
        </p>
      ) : null}

      {canShare ? (
        <button
          type="button"
          onClick={onShare}
          aria-label={copy.shareAria}
          className={cn(
            "inline-flex items-center gap-2 rounded-full border border-gray-200/90 bg-white/90 font-semibold text-gray-700 shadow-sm transition-[border-color,box-shadow,color]",
            "hover:border-primary/25 hover:text-gray-900 hover:shadow-md",
            "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2",
            compact ? "min-h-9 px-3 py-1.5 text-xs" : "min-h-10 px-4 py-2 text-sm",
          )}
        >
          <Share2 className="h-4 w-4 shrink-0" strokeWidth={2} aria-hidden />
          <span>{copy.share}</span>
        </button>
      ) : null}
    </div>
  );
}
