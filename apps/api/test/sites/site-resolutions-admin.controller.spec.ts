import { PATH_METADATA } from '@nestjs/common/constants';
import { SiteResolutionsAdminController } from '../../src/sites/resolutions/controllers/site-resolutions-admin.controller';

describe('SiteResolutionsAdminController routing', () => {
  it('registers under /sites/admin/resolutions (not /sites/resolutions)', () => {
    const path = Reflect.getMetadata(PATH_METADATA, SiteResolutionsAdminController);
    expect(path).toBe('sites/admin/resolutions');
  });
});
