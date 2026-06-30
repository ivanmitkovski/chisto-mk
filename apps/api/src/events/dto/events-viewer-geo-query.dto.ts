import { ViewerGeoNearOptionalDto } from '../../common/dto/geo-point.dto';

/** Optional viewer coordinates for distance-to-site (list + detail). Both must be sent together. */
export class EventsViewerGeoQueryDto extends ViewerGeoNearOptionalDto {}
