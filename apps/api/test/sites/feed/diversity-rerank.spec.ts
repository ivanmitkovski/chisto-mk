import { DiversityRerank } from '../../../src/sites/feed/rerank/diversity-rerank';

describe('DiversityRerank', () => {
  it('avoids repeated category/reporter in first positions when possible', () => {
    const svc = new DiversityRerank();
    const out = svc.apply([
      {
        siteId: '1',
        createdAt: new Date(),
        status: 'VERIFIED',
        latestReportCategory: 'WASTE',
        latestReportReporterId: 'u1',
        rankingScore: 10,
        reportCount: 1,
        upvotesCount: 0,
        commentsCount: 0,
        savesCount: 0,
        sharesCount: 0,
        rankingReasons: [],
      },
      {
        siteId: '2',
        createdAt: new Date(),
        status: 'VERIFIED',
        latestReportCategory: 'WASTE',
        latestReportReporterId: 'u1',
        rankingScore: 9,
        reportCount: 1,
        upvotesCount: 0,
        commentsCount: 0,
        savesCount: 0,
        sharesCount: 0,
        rankingReasons: [],
      },
      {
        siteId: '3',
        createdAt: new Date(),
        status: 'VERIFIED',
        latestReportCategory: 'AIR',
        latestReportReporterId: 'u2',
        rankingScore: 8,
        reportCount: 1,
        upvotesCount: 0,
        commentsCount: 0,
        savesCount: 0,
        sharesCount: 0,
        rankingReasons: [],
      },
      {
        siteId: '4',
        createdAt: new Date(),
        status: 'VERIFIED',
        latestReportCategory: 'WATER',
        latestReportReporterId: 'u3',
        rankingScore: 7,
        reportCount: 1,
        upvotesCount: 0,
        commentsCount: 0,
        savesCount: 0,
        sharesCount: 0,
        rankingReasons: [],
      },
    ]);
    expect(out[0].siteId).toBe('1');
    expect(out.slice(0, 3).map((row) => row.siteId)).toContain('3');
  });
});
