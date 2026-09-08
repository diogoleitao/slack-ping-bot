# No ping data is persisted

The bot has no database and stores nothing about who pinged whom. A ping is delivered and forgotten. This is a scope boundary rather than an omission: ping history, analytics and admin controls were all considered and excluded, and the absence of a store is what makes the privacy claim true rather than merely intended.

## Consequences

There is nothing to migrate, back up, or leak. The only mutable state in the process is the rate limiter's counters and the 5-minute user cache, both of which are disposable.

Anything wanting history reopens this decision rather than extending the system. Ping history, usage analytics, per-target limits and admin allowlists all need a store, so none of them is an incremental feature. They are all in the icebox for exactly this reason.

**Logs are the exception, and the one way this gets broken by accident.** The bot logs `target_user_id`, the DM channel, and the message timestamp on every ping, and the sender's id is inside the message text. That is ping metadata: who pinged whom and when. It is transient on stdout today, but pointing it at a log aggregator with long retention builds the ping history this decision says the system does not keep. Whoever sets up log shipping should decide retention with that in mind.
