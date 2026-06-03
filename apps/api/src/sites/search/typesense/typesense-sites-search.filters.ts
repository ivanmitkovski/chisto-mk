import type { SiteMapSearchDto } from '../../dto/site-map-search.dto';

export function buildTypesenseFilterBy(
  dto: SiteMapSearchDto,
  viewerUserId?: string | null,
): string {
  const clauses: string[] = [];

  if (viewerUserId) {
    clauses.push(`(status:!=REPORTED || reporterUserIds:=${viewerUserId})`);
  } else {
    clauses.push('status:!=REPORTED');
  }

  if (dto.includeArchived !== true) {
    clauses.push('isArchivedByAdmin:=false');
  }

  if (dto.statuses?.length) {
    clauses.push(`status:=[${dto.statuses.join(',')}]`);
  }

  if (dto.pollutionTypes?.length) {
    clauses.push(`pollutionCategories:=[${dto.pollutionTypes.join(',')}]`);
  }

  return clauses.join(' && ');
}

export function buildTypesenseSortBy(dto: SiteMapSearchDto): string | undefined {
  const lat = dto.lat;
  const lng = dto.lng;
  if (lat !== undefined && lng !== undefined) {
    return `_text_match:desc,location(${lat},${lng}):asc,updatedAt:desc`;
  }
  return '_text_match:desc,updatedAt:desc';
}
