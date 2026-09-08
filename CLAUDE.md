# Claude Session Context

This file provides context for AI assistants (Claude, ChatGPT, etc.) working on this codebase.

---

## Project Overview

**Slack Ping Bot** - A high-performance Slack bot that sends ephemeral notification pings.

**Key Characteristic:** Messages are sent and deleted within 150ms, but notifications persist for the recipient.

---

## Current Status

**Implementation:** ✅ Complete  
**Automated testing:** ✅ Complete (RSpec suite, 96% coverage)  
**CI:** ⏳ Pending ([#2](https://github.com/diogoleitao/slack-ping-bot/issues/2))  
**Manual test pass:** ⏳ Pending (`scripts/setup-slack.sh`)  
**Deployment:** ⏳ Pending ([#9](https://github.com/diogoleitao/slack-ping-bot/issues/9))

All code is written and functional, with an RSpec unit and integration suite. Nothing runs the suite automatically yet, and the bot has never been deployed.

Remaining work is tracked in [GitHub Issues](https://github.com/diogoleitao/slack-ping-bot/issues), not in this file. See `docs/agents/issue-tracker.md` for the conventions.

---

## Technology Stack

- **Ruby 3.4.8** (latest stable)
- **YJIT enabled** (15-25% performance boost)
- **Sinatra 4.2** (web framework)
- **Puma 7.1** (web server)
- **Redis 5.4** (rate limiting with in-memory fallback)
- **Ougai 2.0** (structured JSON logging)
- **Docker** (containerization support)

---

## Project Structure

```
slack-ping-bot/
├── app.rb                  # Main Sinatra app (87 lines)
├── lib/
│   ├── slack_verifier.rb  # HMAC-SHA256 signature validation
│   ├── slack_client.rb    # Slack API wrapper with caching
│   ├── rate_limiter.rb    # Redis + in-memory fallback
│   ├── user_resolver.rb   # User mention parsing/validation
│   └── ping_handler.rb    # Core orchestration logic
├── config/
│   └── puma.rb            # Web server config
├── scripts/
│   └── setup-slack.sh     # Wizard: Slack app setup + 33-item manual test pass
├── Gemfile                # Ruby 3.4 dependencies
├── Dockerfile             # Ruby 3.4-alpine with YJIT
├── docker-compose.yml     # App + Redis setup
├── .env.example           # Environment template
├── README.md              # User documentation
├── CONTEXT.md             # Domain glossary: ping, sender, target, notification
├── docs/
│   ├── IMPLEMENTATION.md  # Complete technical docs (1,832 lines)
│   ├── adr/               # Why the surprising decisions are what they are
│   └── agents/            # Per-repo config read by the engineering skills
│       ├── issue-tracker.md   # Where issues live (GitHub, via gh CLI)
│       ├── triage-labels.md   # Canonical triage label vocabulary
│       └── domain.md          # CONTEXT.md / ADR consumer rules
└── CLAUDE.md              # This file
```

---

## Architecture

### Request Flow

```
Slack → POST /slack/commands
  ↓
SlackVerifier (signature validation)
  ↓
app.rb (parse payload)
  ↓
PingHandler.execute
  ├─ UserResolver (validate target)
  ├─ RateLimiter (check 3/min limit)
  └─ SlackClient (send → wait 150ms → delete)
  ↓
Return ephemeral response
```

### Key Design Decisions

1. **Logger Injection Pattern**: All classes accept optional `logger` parameter with default `Ougai::Logger.new($stdout)`
2. **Redis Fallback**: Gracefully degrades to thread-safe in-memory hash if Redis unavailable
3. **User Caching**: 5-minute TTL on user list to reduce Slack API calls
4. **Constant-Time Comparison**: Security signature verification uses constant-time comparison
5. **Ephemeral Errors**: All error messages only visible to command sender

---

## Important Context

### What Makes This Bot Unique

**The 150ms Delete Window:**
- Messages must be sent, persist long enough for notification, then deleted
- Sweet spot: 100-200ms (we use 150ms)
- Too fast: Notification might not trigger
- Too slow: Message visible to recipient

**Rate Limiting Scope:**
- Only applies to SENDER (not recipient)
- Prevents spam from one user
- No limit on receiving pings

### Validation Rules

Cannot ping:
- Yourself (self-ping blocked)
- Bot users (is_bot flag)
- Deactivated users (deleted flag)
- Users with DMs disabled (graceful error)

### Security Features

- HMAC-SHA256 request signature validation
- Replay attack protection (reject >5min old)
- Constant-time string comparison
- No data persistence (privacy by design)

---

## Code Conventions

### RuboCop

**Linting:** RuboCop with `rubocop-performance` and `rubocop-rake` extensions

**Configuration:**
- Single quotes for strings, double for interpolation
- 120 character line length
- No code comments (code should be self-documenting)
- Documentation comments disabled
- Adjusted metrics: MethodLength max 40, AbcSize max 25, ParameterLists max 6
- Pre-commit hook blocks commits on violations (skippable with `--no-verify`)

**Run linting:**
```bash
bundle exec rubocop              # Check all files
bundle exec rubocop -A           # Auto-fix safe offenses
bundle exec rubocop lib/*.rb     # Check specific files
bundle exec rubocop --format offenses  # View counts by type
```

**Configuration file:** `.rubocop.yml`

**Pre-commit hook:** `.git-hooks/pre-commit` (runs on staged Ruby files)

### Logging Style

**Before (removed):**
```ruby
puts "[INFO] Message sent"
```

**After (current):**
```ruby
logger.info('Message sent', user_id: user_id, channel: channel)
```

**Output format:**
```json
{"level":30,"msg":"Message sent","user_id":"U123","channel":"C456"}
```

### Error Handling

All errors return structured hash:
```ruby
{ success: false, error: 'User not found' }
{ success: true, message: 'Pinged <@U123>' }
```

### Module Pattern

Stateless modules use `self.method_name`:
```ruby
module UserResolver
  def self.resolve(channel_id, text, sender_id, slack_client)
    # ...
  end
end
```

Stateful classes use instance methods:
```ruby
class SlackClient
  def initialize(token, logger: Ougai::Logger.new($stdout))
    @logger = logger
    # ...
  end
end
```

---

## Development Workflow

### Running Locally

```bash
# Start Redis (optional)
docker run -d -p 6379:6379 redis:alpine

# Copy environment
cp .env.example .env
# Edit .env with Slack credentials

# Install dependencies
bundle install

# Development mode (auto-reload)
bundle exec rerun 'rackup -p 4567'

# Production mode (with YJIT)
RUBY_YJIT_ENABLE=1 bundle exec puma -C config/puma.rb

# With pretty logs
bundle exec puma -C config/puma.rb | bunyan
```

### Testing with ngrok

```bash
ngrok http 4567
# Update Slack app URL: https://xxx.ngrok.io/slack/commands
```

---

## Common Tasks

### Adding New Environment Variable

1. Add to `.env.example` with comment
2. Add to `docker-compose.yml` if needed
3. Update `README.md` configuration section
4. Update `docs/IMPLEMENTATION.md` deployment section

### Adding New Validation Rule

1. Update `lib/user_resolver.rb#validate_user`
2. Add a spec case to `spec/lib/user_resolver_spec.rb`
3. Add the manual check to the validation stage of `scripts/setup-slack.sh`
4. Update error message docs in `README.md`

### Changing Rate Limit

1. Update constants in `lib/rate_limiter.rb`:
   - `MAX_PINGS` (default: 3)
   - `WINDOW_SECONDS` (default: 60)
2. Update documentation in `README.md`

### Adding New Log Level

Current levels: trace, debug, info, warn, error, fatal

To add custom structured fields:
```ruby
logger.info('Event name',
  required_field: value,
  optional_field: value,
  context: { nested: 'data' }
)
```

### Running RuboCop

```bash
# Full audit
bundle exec rubocop

# Auto-fix safe offenses
bundle exec rubocop -A

# Check single file
bundle exec rubocop app.rb

# Fix all staged files before commit
git diff --cached --name-only | grep '\.rb$' | xargs bundle exec rubocop -A
```

---

## File Purposes

| File | Purpose | Lines | Key Info |
|------|---------|-------|----------|
| `app.rb` | Main Sinatra app | 87 | Entry point, request handling |
| `lib/slack_verifier.rb` | Security | 47 | HMAC signature validation |
| `lib/slack_client.rb` | Slack API | 95 | User caching, API wrapper |
| `lib/rate_limiter.rb` | Rate limiting | 93 | Redis + in-memory fallback |
| `lib/user_resolver.rb` | User validation | 95 | Mention parsing, validation |
| `lib/ping_handler.rb` | Orchestration | 70 | Coordinates all modules |
| `README.md` | User docs | 424 | Installation, usage, troubleshooting |
| `docs/IMPLEMENTATION.md` | Technical docs | 1,832 | Complete spec, all file contents |
| `scripts/setup-slack.sh` | Setup wizard | 380 | Slack app config + 33-item manual test pass |
| `CONTEXT.md` | Domain glossary | - | Canonical terms: ping, sender, target, notification |
| `docs/adr/` | Decision records | - | 150ms window, Redis fallback, no persistence |
| `docs/agents/issue-tracker.md` | Skill config | - | Issues live in GitHub, `gh` CLI conventions |
| `docs/agents/triage-labels.md` | Skill config | - | Triage role to label-string mapping |
| `docs/agents/domain.md` | Skill config | - | How skills read `CONTEXT.md` and ADRs |
| `CLAUDE.md` | This file | - | AI assistant context |

---

## Testing Strategy

**Automated:** RSpec suite in `spec/` at 96% coverage. 5 unit specs under `spec/lib/`, 3 integration specs under `spec/integration/`, with fixtures, VCR cassettes and mock_redis. Run with `bundle exec rspec`.  
**Manual:** 33-item checklist, driven by `scripts/setup-slack.sh`. Covers what specs cannot: that the 150ms delete window actually leaves a notification behind in a real workspace.  
**CI:** not yet wired up. See [#2](https://github.com/diogoleitao/slack-ping-bot/issues/2).

**Test with:**
```bash
# Valid ping
/ping @username

# DM ping
/ping

# Error cases
/ping @invalid_user
/ping @self
/ping @bot
```

---

## Deployment Targets

**Supported platforms:**
- Heroku (documented)
- Fly.io (documented)
- Railway (documented)
- Docker (docker-compose.yml ready)

**Required environment variables:**
- `SLACK_BOT_TOKEN` (required)
- `SLACK_SIGNING_SECRET` (required)
- `REDIS_URL` (optional, falls back to in-memory)
- `RUBY_YJIT_ENABLE=1` (recommended)
- `LOG_LEVEL=info` (optional)

---

## Known Limitations

1. **No ping history** - No persistence by design
2. **Single workspace** - One Slack workspace per deployment
3. **Fixed message format** - "👋 Ping from @user" only
4. **No admin controls** - Configuration via environment variables
5. **Rate limits are not durable without Redis** - The in-memory fallback resets counters on restart and is only correct for a single app instance

---

## Future Enhancements (Out of Scope)

Held in the icebox issue [#3](https://github.com/diogoleitao/slack-ping-bot/issues/3), none of them committed to:
- Custom messages
- Ping history/analytics
- Admin controls
- Scheduled pings
- Multi-workspace support
- Web dashboard

Note that ping history, analytics and multi-workspace each contradict a current design decision, so none is a free addition.

---

## Troubleshooting Tips

### "Invalid signature" errors
- Check `SLACK_SIGNING_SECRET` matches Slack app
- Verify server time is synchronized

### Rate limiting not working
- Check Redis connection: `redis-cli ping`
- Review logs for "in-memory fallback" message
- Verify `REDIS_URL` format

### User not found
- Username must match exactly (case-insensitive)
- Try user ID format: `/ping <@U12345>`
- Check user not deactivated

### YJIT not working
```bash
ruby --yjit -e "puts RubyVM::YJIT.enabled?"  # Should output: true
echo $RUBY_YJIT_ENABLE  # Should output: 1
```

---

## Useful Commands

```bash
# Check logs
tail -f log/production.log | bunyan

# Filter errors only
cat log/production.log | jq 'select(.level == 50)'

# Check Redis
redis-cli ping
redis-cli keys "ping:limit:*"

# Test health endpoint
curl http://localhost:4567/

# Check Ruby version
ruby --version  # Should show 3.4.8

# Verify gems
bundle exec ruby -e "require 'ougai'; puts 'OK'"

# Lint all files
bundle exec rubocop

# Lint with offense counts
bundle exec rubocop --format offenses

# Lint only changed files
git diff --name-only main | grep '\.rb$' | xargs bundle exec rubocop
```

---

## Git Workflow

**Commit Message Format:**

This project uses [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) - **enforced via git hooks**.

**Format:**
```
type(scope): subject
type!(scope): subject  (breaking change)
```

**Types:** feat, fix, docs, style, refactor, perf, test, chore  
**Scope:** Optional (ping, rate-limiter, logging, etc.)  
**Subject:** Imperative mood, max 72 chars, no period

**Examples:**
```
feat(ping): add scheduled ping support
fix(rate-limiter): resolve Redis fallback
feat!(api): change rate limit to 5 per minute
docs: update installation steps
```

**Enforcement:** Invalid commit messages are rejected by the commit-msg hook.

See `CONTRIBUTING.md` for complete guidelines.

### Semantic Versioning

This project uses [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

**Current version:** `0.1.0` (stored in `VERSION` and `lib/version.rb`)

**Version bumps** based on conventional commits:
- `feat!:` or `fix!:` → MAJOR (breaking changes)
- `feat:` → MINOR (new features)
- `fix:` → PATCH (bug fixes)
- Other types → No version change

**Version 1.0.0 milestone:** First production deployment. Tracked as [#16](https://github.com/diogoleitao/slack-ping-bot/issues/16), which lists what gates it.

**Release automation:** See `CONTRIBUTING.md` for the manual process and [#7](https://github.com/diogoleitao/slack-ping-bot/issues/7) for the automation that replaces it. No git tags exist yet, so `v0.1.0` needs tagging retroactively before the first automated release has a baseline.

**When making changes:**
1. Create feature branch: `git checkout -b feat/feature-name`
2. Make changes and test
3. Update relevant docs (README.md, docs/IMPLEMENTATION.md)
4. Commit following conventional format
5. Merge to main when tested

---

## Questions to Ask User

When starting a new session, consider asking:

1. **"What do you want to work on?"**
   - Check the unblocked issues first: `gh issue list --state open` and drop any with an open blocker
   - Right now the frontier is [#1](https://github.com/diogoleitao/slack-ping-bot/issues/1) (pick a platform), [#2](https://github.com/diogoleitao/slack-ping-bot/issues/2) (wire up CI) and [#3](https://github.com/diogoleitao/slack-ping-bot/issues/3) (triage the icebox)
   - Bug fix?

2. **"Is the Slack app configured?"**
   - If no: run `scripts/setup-slack.sh`, which walks the whole procedure
   - If yes: Proceed with testing

3. **"Any errors in the logs?"**
   - Check for JSON log entries with `level: 50` (error)

4. **"Do you want me to explain any part of the code?"**
   - Architecture? (see docs/IMPLEMENTATION.md section 4)
   - Specific module? (see section 5)

---

## Quick Reference

**Start coding:**
```bash
cd /Users/diogoleitao/repos/slack-ping-bot
bundle install  # Already done
code .          # Or cursor .
```

**Read documentation:**
- User guide: `README.md`
- Technical details: `docs/IMPLEMENTATION.md`
- Next steps: [GitHub Issues](https://github.com/diogoleitao/slack-ping-bot/issues)
- This context: `CLAUDE.md`

**Environment:**
- Ruby: 3.4.8 (rbenv)
- Platform: macOS (arm64-darwin24)
- Working directory: `/Users/diogoleitao/repos/slack-ping-bot/`

---

## Key Files to Read First

When starting a new session:

1. **This file (CLAUDE.md)** - You're here! ✓
2. **`gh issue list --state open`** - See what's next
3. **app.rb** - Understand request flow
4. **lib/ping_handler.rb** - Core business logic

For deep dive:
5. **docs/IMPLEMENTATION.md** - Complete technical documentation

---

## Agent skills

### Issue tracker

Issues live as GitHub issues in `diogoleitao/slack-ping-bot`, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage labels, unrenamed: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` plus `docs/adr/` at the repo root. See `docs/agents/domain.md`.

Read `CONTEXT.md` before naming anything: it settles sender vs target, and ping vs notification. Read the ADRs before changing the code they cover:

- [ADR-0001](docs/adr/0001-delete-the-ping-message-after-150ms.md): the 150ms sleep in `PingHandler` is deliberate and load-bearing
- [ADR-0002](docs/adr/0002-rate-limiting-degrades-to-in-memory.md): Redis is optional, and the fallback is permanent for the process
- [ADR-0003](docs/adr/0003-no-ping-data-is-persisted.md): no store by design, and logs are how that gets broken by accident

---

**Last Updated:** September 8, 2026  
**Status:** Implementation and automated test suite complete. Not yet deployed, no CI.  
**Next Step:** Work the unblocked issues: [#1](https://github.com/diogoleitao/slack-ping-bot/issues/1) pick a deployment platform, [#2](https://github.com/diogoleitao/slack-ping-bot/issues/2) wire up CI. For the Slack app itself, run `scripts/setup-slack.sh`.
