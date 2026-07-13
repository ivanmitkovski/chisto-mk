import type { ReactNode } from "react";
import {
  ShareDocumentLayout,
  shareDocumentMetadata,
  shareDocumentViewport,
} from "@/components/layout/ShareDocumentLayout";

export const metadata = shareDocumentMetadata;
export const viewport = shareDocumentViewport;

export default function EventsShareLayout({ children }: { children: ReactNode }) {
  return <ShareDocumentLayout>{children}</ShareDocumentLayout>;
}
