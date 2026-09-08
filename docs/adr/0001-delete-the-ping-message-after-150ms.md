# Delete the ping message 150ms after sending it

A ping must notify the target without leaving a message in their DM history, and Slack offers no API for "notify without posting". So the bot posts a real message, sleeps 150ms, then deletes it: long enough for Slack to have raised the notification, short enough that the message is gone before the target could read it. `PingHandler::DELETION_DELAY_MS` holds the number, and the useful band is roughly 100-200ms. Below it the notification may not fire; above it the message starts being visible.

## Consequences

The `sleep` in `PingHandler.execute` is deliberate and load-bearing. It looks exactly like the kind of blocking call worth removing from a request path, and removing it breaks the product.

It is a synchronous sleep, so it holds its Puma thread for the duration on top of three Slack API round trips (open DM, post, delete). Throughput per thread is capped accordingly.

The 150ms figure was chosen against local latency and has never been measured against production. The window is a race with Slack's notification pipeline, so a deployment far from Slack's infrastructure can land outside the band in either direction. Verify it after deploying rather than assuming it carries over.

Failure is asymmetric and worth remembering when tuning: too fast means no notification, which is a ping that silently did nothing; too slow means a visible message, which is the one outcome the bot exists to avoid.
