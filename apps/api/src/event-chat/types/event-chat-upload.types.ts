export interface ProcessedAttachment {
  url: string;
  mimeType: string;
  fileName: string;
  sizeBytes: number;
  width: number | null;
  height: number | null;
  duration: number | null;
  thumbnailUrl: string | null;
}
