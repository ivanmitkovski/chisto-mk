export type ReportStatus = 'NEW' | 'IN_REVIEW' | 'APPROVED' | 'DELETED';
export type ReportPriority = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';

export type ReportEvidence = {
  id: string;
  label: string;
  kind: 'image' | 'video' | 'document';
  sizeLabel: string;
  uploadedAt: string;
  previewUrl?: string | undefined;
  previewAlt?: string | undefined;
};

export type ReportTimelineEntry = {
  id: string;
  title: string;
  detail: string;
  actor: string;
  occurredAt: string;
  tone: 'neutral' | 'success' | 'warning' | 'info';
};

export type ReportModerationMeta = {
  queueLabel: string;
  slaLabel: string;
  assignedTeam: string;
};

export type ReportMapPin = {
  latitude: number;
  longitude: number;
  label: string;
};

export type ReportRow = {
  id: string;
  reportNumber: string;
  name: string;
  location: string;
  dateReportedAt: string;
  status: ReportStatus;
  isPotentialDuplicate: boolean;
  coReporterCount: number;
};

export type ReportDetail = {
  id: string;
  reportNumber: string;
  status: ReportStatus;
  priority: ReportPriority;
  title: string;
  description: string;
  location: string;
  submittedAt: string;
  reporterAlias: string;
  reporterTrust: 'Bronze' | 'Silver' | 'Gold';
  evidence: ReportEvidence[];
  timeline: ReportTimelineEntry[];
  moderation: ReportModerationMeta;
  mapPin: ReportMapPin;
  isPotentialDuplicate: boolean;
  coReporters: string[];
  potentialDuplicateOfReportNumber?: string;
};

export type StatusFilter = 'ALL' | ReportStatus;
export type SortDirection = 'asc' | 'desc';
export type SortKey = 'reportNumber' | 'name' | 'location' | 'dateReportedAt' | 'status';
