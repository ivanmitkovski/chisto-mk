export type CandidateRequestContext = {
  userId?: string;
  lat?: number;
  lng?: number;
  radiusKm?: number;
  limit?: number;
  status?: 'REPORTED' | 'VERIFIED' | 'CLEANUP_SCHEDULED' | 'IN_PROGRESS' | 'CLEANED' | 'DISPUTED';
};
