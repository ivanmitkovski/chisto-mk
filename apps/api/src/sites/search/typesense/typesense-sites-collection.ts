export const TYPESENSE_SITES_COLLECTION_FIELDS = [
  { name: 'id', type: 'string' as const },
  { name: 'latitude', type: 'float' as const },
  { name: 'longitude', type: 'float' as const },
  { name: 'description', type: 'string' as const, optional: true },
  { name: 'address', type: 'string' as const, optional: true },
  { name: 'status', type: 'string' as const, facet: true },
  { name: 'isArchivedByAdmin', type: 'bool' as const, facet: true },
  { name: 'pollutionCategories', type: 'string[]' as const, facet: true, optional: true },
  { name: 'reporterUserIds', type: 'string[]' as const, facet: true, optional: true },
  { name: 'updatedAt', type: 'int64' as const },
  { name: 'location', type: 'geopoint' as const },
];

export type TypesenseSiteDocument = {
  id: string;
  latitude: number;
  longitude: number;
  description?: string;
  address?: string;
  status: string;
  isArchivedByAdmin: boolean;
  pollutionCategories?: string[];
  reporterUserIds?: string[];
  updatedAt: number;
  location: [number, number];
};
