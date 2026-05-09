/**
 * Atomic fixed-window counter with TTL (single round-trip).
 * KEYS[1] = redis key, ARGV[1] = ttl seconds. Returns count after INCR.
 */
export const MAP_RATE_LIMIT_INCR_SCRIPT = `
local c = redis.call('INCR', KEYS[1])
if c == 1 then
  redis.call('EXPIRE', KEYS[1], tonumber(ARGV[1]))
end
return c
`;
