export type ReportViewerPresenceEntry = {
  sessionId: string;
  userId: string;
  displayName: string;
};

export type ReportViewersUpdatedEvent = {
  type: 'report_viewers_updated';
  reportId: string;
  viewers: ReportViewerPresenceEntry[];
};
