import { CandidateGenerator } from '../../../src/sites/feed/candidates/candidate-generator';

describe('CandidateGenerator', () => {
  it('dedupes same site id and keeps higher score hint', async () => {
    const geo = {
      retrieve: jest.fn().mockResolvedValue([
        {
          siteId: 'site_1',
          createdAt: new Date(),
          status: 'VERIFIED',
          latestReportCategory: null,
          latestReportReporterId: null,
          rankingScore: 0,
          reportCount: 1,
          upvotesCount: 0,
          commentsCount: 0,
          savesCount: 0,
          sharesCount: 0,
          rankingReasons: [],
          candidateStage: { retriever: 'geo', scoreHint: 0.5 },
        },
      ]),
    };
    const freshness = {
      retrieve: jest.fn().mockResolvedValue([
        {
          siteId: 'site_1',
          createdAt: new Date(),
          status: 'VERIFIED',
          latestReportCategory: null,
          latestReportReporterId: null,
          rankingScore: 0,
          reportCount: 1,
          upvotesCount: 0,
          commentsCount: 0,
          savesCount: 0,
          sharesCount: 0,
          rankingReasons: [],
          candidateStage: { retriever: 'freshness', scoreHint: 0.9 },
        },
      ]),
    };
    const engagement = { retrieve: jest.fn().mockResolvedValue([]) };
    const personal = { retrieve: jest.fn().mockResolvedValue([]) };
    const svc = new CandidateGenerator(geo as never, freshness as never, engagement as never, personal as never);
    const out = await svc.generate({});
    expect(out).toHaveLength(1);
    expect(out[0].candidateStage.retriever).toBe('freshness');
  });
});
