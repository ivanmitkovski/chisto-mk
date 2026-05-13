import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';

/** Pagination-only query (defaults match {@link PaginationQueryDto}: page 1, limit 50). */
export class ListCheckInRiskSignalsQueryDto extends PaginationQueryDto {}
