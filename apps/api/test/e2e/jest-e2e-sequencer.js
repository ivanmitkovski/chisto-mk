const Sequencer = require('@jest/test-sequencer').default;

/** Run infra readiness specs before auth-heavy suites to avoid connection-pool pressure at the end. */
class E2eTestSequencer extends Sequencer {
  sort(tests) {
    const sorted = super.sort(tests);
    const priority = (path) => {
      if (path.includes('cluster-redis.e2e-spec')) return 0;
      if (path.includes('health.e2e-spec')) return 1;
      if (path.includes('throttling.e2e-spec')) return 98;
      if (path.includes('validation-errors.e2e-spec')) return 99;
      return 50;
    };
    return sorted.sort((a, b) => priority(a.path) - priority(b.path));
  }
}

module.exports = E2eTestSequencer;
