# Claude Session Context

This file provides context for AI assistants (Claude, ChatGPT, etc.) working on this codebase.

---

## Project Overview

**Slack Ping Bot** - A high-performance Slack bot that sends ephemeral notification pings.

**Key Characteristic:** Messages are sent and deleted within 150ms, but notifications persist for the recipient.

---

## Current Status

**Implementation:** ✅ Complete  
**Testing:** ⏳ Pending (see docs/TODO.md)  
**Deployment:** ⏳ Pending (see docs/TODO.md)

All code is written and functional. Dependencies installed. Ready for Slack app configuration and testing.

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
├── Gemfile                # Ruby 3.4 dependencies
├── Dockerfile             # Ruby 3.4-alpine with YJIT
├── docker-compose.yml     # App + Redis setup
├── .env.example           # Environment template
├── README.md              # User documentation
├── docs/
│   ├── IMPLEMENTATION.md  # Complete technical docs (1,832 lines)
│   └── TODO.md            # Roadmap and testing checklist (190 lines)
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
2. Add test case to `docs/TODO.md` checklist
3. Update error message docs in `README.md`

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
| `docs/TODO.md` | Roadmap | 190 | Testing checklist, deployment steps |
| `CLAUDE.md` | This file | - | AI assistant context |

---

## Testing Strategy

**Current:** Manual testing checklist (33 items in docs/TODO.md)  
**Future:** RSpec unit + integration tests (see docs/TODO.md section 7)

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

1. **No automated tests** - Manual checklist only
2. **No ping history** - No persistence by design
3. **Single workspace** - One Slack workspace per deployment
4. **Fixed message format** - "👋 Ping from @user" only
5. **No admin controls** - Configuration via environment variables

---

## Future Enhancements (Out of Scope)

See `docs/TODO.md` section 9 for full list:
- Custom messages
- Ping history/analytics
- Admin controls
- Scheduled pings
- Multi-workspace support
- Web dashboard

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

**Version 1.0.0 milestone:** First production deployment after completing `docs/TODO.md`

**Release automation:** See `CONTRIBUTING.md` for manual process and `docs/TODO.md` section 7 for CI/CD setup.

**When making changes:**
1. Create feature branch: `git checkout -b feat/feature-name`
2. Make changes and test
3. Update relevant docs (README.md, docs/IMPLEMENTATION.md, docs/TODO.md)
4. Commit following conventional format
5. Merge to main when tested

---

## Questions to Ask User

When starting a new session, consider asking:

1. **"What do you want to work on?"**
   - Testing? (see docs/TODO.md section 3)
   - Deployment? (see docs/TODO.md section 4)
   - New feature? (see docs/TODO.md section 9)
   - Bug fix?

2. **"Is the Slack app configured?"**
   - If no: Guide through docs/TODO.md section 1
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
- Next steps: `docs/TODO.md`
- This context: `CLAUDE.md`

**Environment:**
- Ruby: 3.4.8 (rbenv)
- Platform: macOS (arm64-darwin24)
- Working directory: `/Users/diogoleitao/repos/slack-ping-bot/`

---

## Key Files to Read First

When starting a new session:

1. **This file (CLAUDE.md)** - You're here! ✓
2. **docs/TODO.md** - See what's next
3. **app.rb** - Understand request flow
4. **lib/ping_handler.rb** - Core business logic

For deep dive:
5. **docs/IMPLEMENTATION.md** - Complete technical documentation

---

**Last Updated:** December 23, 2025  
**Status:** Implementation complete, ready for Slack app configuration and testing  
**Next Step:** Follow docs/TODO.md section 1 (Slack App Configuration)
