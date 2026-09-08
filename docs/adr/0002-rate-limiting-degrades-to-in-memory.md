# Rate limiting degrades to in-memory rather than failing

Rate limiting exists to stop one sender spamming, not to protect correctness, so `RateLimiter` treats Redis as optional: if Redis is unreachable at startup or errors at runtime, it falls back to a mutex-guarded in-process hash and keeps serving. A ping bot that refuses to ping because a cache is down would be a worse product than one that briefly limits less precisely.

## Consequences

Redis is genuinely optional. The bot runs correctly with `REDIS_URL` unset, which makes "no Redis" a legitimate deployment choice rather than a broken one.

The fallback is per process. Two app instances keep separate counters, so the effective limit becomes 3 pings per minute per instance, and counters reset on every restart and deploy. In-memory limiting is only correct while exactly one instance runs, and that constraint is invisible in the code.

The demotion is permanent for the life of the process. `check_redis` sets `@redis = nil` on any `Redis::BaseError` and never retries, so a transient blip moves a long-lived process to in-memory until it restarts. This is deliberate, in that it avoids retrying a dead connection on every request, but it means Redis being healthy again does not restore durable limiting on its own.

Degradation is silent by design at runtime, which is right for the request and wrong for operations. Nothing distinguishes "limiting durably" from "limiting per process" without reading the logs for the fallback warning. Making that visible is the point of the Redis availability metric.

## A related documentation error

The window is fixed, not rolling, in both paths: the first ping starts a 60-second window and the counter resets when it expires. `README.md` and `CLAUDE.md` both describe it as a "rolling 60-second window", which is wrong. Either the docs or the implementation should change; this ADR does not decide which.
