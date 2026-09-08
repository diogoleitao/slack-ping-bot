# Slack Ping Bot

Gets one person's attention in Slack without leaving anything behind. The bot sends a message, waits long enough for Slack to raise a notification, then deletes it: the target is notified, and their DM history stays clean.

## Language

**Ping**:
A notification delivered to one person with nothing left behind. Sending and deleting are one act, not two steps. A message that survives is a failed ping.
_Avoid_: Nudge, poke, buzz

**Sender**:
The person who invokes `/ping`. The only party any limit applies to.
_Avoid_: Caller, invoker, requester, user

**Target**:
The person a ping is aimed at. Named by mention in a channel, or implied by the conversation in a DM.
_Avoid_: Recipient, receiver, pingee, user

**Notification**:
The alert Slack raises on the target's device, and the only thing a ping leaves behind. This is the deliverable: the message is merely how it gets raised.
_Avoid_: Alert, badge

**Mention**:
The text naming a target. Two forms are accepted: a bare `@username` matched exactly and case-insensitively, or Slack's own `<@U12345>` encoding. A partial name is refused rather than resolved, since pinging the wrong person is worse than not pinging at all.
_Avoid_: Handle, tag, username reference

**Self-ping**:
A sender targeting themselves. Always refused.

**Ephemeral response**:
A reply Slack shows only to the sender. Every failure the bot reports is one, so a mistyped name never becomes visible to a channel.
_Avoid_: Private reply, silent error

## Terms deliberately not defined here

**Rate limiting**, **fallback**, and **caching** are general engineering concepts, not vocabulary specific to this bot. What is specific, and belongs above, is that limits are scoped to the sender alone: receiving pings is never restricted.
