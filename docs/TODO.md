# Slack Ping Bot - TODO

## Status: Ready for Testing

All core implementation complete. The following items remain before production deployment.

---

## High Priority

### 1. Slack App Configuration
- [ ] Create Slack app at https://api.slack.com/apps
- [ ] Configure Bot Token Scopes: `chat:write`, `users:read`, `im:write`, `commands`
- [ ] Install app to workspace
- [ ] Copy Bot User OAuth Token (xoxb-...)
- [ ] Configure `/ping` slash command with request URL
- [ ] Copy Signing Secret from Basic Information
- [ ] Update `.env` file with credentials

### 2. Local Testing
- [ ] Start Redis (or verify in-memory fallback works)
- [ ] Run application locally with ngrok
- [ ] Update Slack app with ngrok URL
- [ ] Execute manual testing checklist (see below)

### 3. Manual Testing Checklist

**Basic Functionality:**
- [ ] Health endpoint responds (`GET /`)
- [ ] `/ping` in DM sends notification
- [ ] `/ping @username` in channel works
- [ ] Message appears and disappears (~150ms)
- [ ] Notification persists after deletion

**Username Resolution:**
- [ ] `/ping @username` matches exact username (case-insensitive)
- [ ] `/ping <@U12345>` with user ID works
- [ ] `/ping @invalid` shows error
- [ ] Partial match shows error

**Validation:**
- [ ] Cannot ping yourself
- [ ] Cannot ping bot users
- [ ] Cannot ping deactivated users
- [ ] Invalid format shows helpful error

**Rate Limiting:**
- [ ] First 3 pings succeed
- [ ] 4th ping fails with rate limit error
- [ ] Wait 60 seconds, ping succeeds again
- [ ] Rate limit works with Redis down (in-memory fallback)

**Security:**
- [ ] Invalid signature rejected (401)
- [ ] Old timestamp rejected (>5 min)
- [ ] Valid signature accepted

**Error Handling:**
- [ ] User not found shows error
- [ ] Cannot send DM error (user has DMs disabled)
- [ ] API errors show generic message
- [ ] All errors are ephemeral (sender only)

**Logging:**
- [ ] JSON format output working
- [ ] Log level filtering works (`LOG_LEVEL=debug`)
- [ ] Structured fields present in logs
- [ ] Bunyan formatter works (optional)

---

## Medium Priority

### 4. Deployment
- [ ] Choose deployment platform (Heroku/Fly.io/Railway/Docker)
- [ ] Set up production Redis instance
- [ ] Configure environment variables
- [ ] Deploy application
- [ ] Update Slack app with production URL
- [ ] Test in production environment

### 5. Monitoring Setup
- [ ] Set up log aggregation (Datadog/CloudWatch/Splunk/ELK)
- [ ] Configure alerts for errors
- [ ] Set up uptime monitoring
- [ ] Configure performance metrics
- [ ] Track key metrics:
  - Request rate (requests/minute)
  - Success rate (%)
  - Rate limit hit rate (%)
  - Average response time (ms)
  - Redis availability (%)

### 6. Documentation
- [ ] Add deployment-specific instructions to README
- [ ] Document any deployment gotchas
- [ ] Add monitoring/alerting setup guide

---

## Low Priority (Future Enhancements)

### 7. Automated Testing
- [ ] Set up RSpec test framework
- [ ] Write unit tests for all modules:
  - [ ] `spec/lib/slack_verifier_spec.rb`
  - [ ] `spec/lib/user_resolver_spec.rb`
  - [ ] `spec/lib/rate_limiter_spec.rb`
  - [ ] `spec/lib/ping_handler_spec.rb`
  - [ ] `spec/lib/slack_client_spec.rb`
- [ ] Write integration tests:
  - [ ] `spec/integration/ping_flow_spec.rb`
- [ ] Set up CI/CD pipeline
- [ ] Add test coverage reporting

### 8. Performance Testing
- [ ] Run load tests (Apache Bench or similar)
- [ ] Verify YJIT performance gains
- [ ] Test with high concurrent load
- [ ] Optimize if needed

### 9. Additional Features (Out of Scope)

*These were explicitly excluded from initial requirements but could be added later:*

- [ ] Custom messages: `/ping @user "check this out"`
- [ ] Ping history: Log pings to database
- [ ] Analytics: Track usage statistics
- [ ] Admin controls: Allowlist/blocklist users
- [ ] Per-target rate limiting: Prevent ping spam to one user
- [ ] Scheduled pings: `/ping @user at 2pm`
- [ ] Ping acknowledgments: Recipient can reply
- [ ] Rich formatting: Embeds, buttons, etc.
- [ ] Multi-workspace: Support multiple Slack workspaces
- [ ] Web dashboard: View stats, configure settings

---

## Blockers

**None currently.** All dependencies installed, code complete, ready for testing.

---

## Next Immediate Steps

1. **Configure Slack App** (30 minutes)
   - Create app, get tokens, configure slash command

2. **Test Locally** (1 hour)
   - Run with ngrok, execute full manual testing checklist

3. **Deploy to Production** (1-2 hours)
   - Choose platform, deploy, configure production environment

**Estimated time to production:** 2.5-3.5 hours

---

## Questions/Decisions Needed

- [ ] Which deployment platform? (Heroku/Fly.io/Railway/Docker on cloud)
- [ ] Which log aggregation service? (if any)
- [ ] Redis hosting decision (managed service or self-hosted)
- [ ] Domain name for production deployment
- [ ] Monitoring/alerting service preference

---

## Known Limitations

1. **No automated tests** - Only manual testing checklist provided
2. **No database** - No persistence of ping history or analytics
3. **Single workspace** - Bot works in one Slack workspace only
4. **No admin UI** - Configuration via environment variables only
5. **Fixed message format** - Cannot customize ping message content

---

## Git Repository Setup

**Complete before making any commits.**

### 1. Initialize Repository

- [ ] Run `git init` to initialize repository
- [ ] Verify `.git` directory created: `ls -la .git/`
- [ ] Check `.gitignore` excludes `.env`: `grep -q "^\.env$" .gitignore && echo "OK"`

### 2. Install Git Hooks

- [ ] Run installation script: `./git-hooks/install.sh`
- [ ] Verify hook installed: `ls -l .git/hooks/commit-msg`
- [ ] Hook should be executable (permissions: `-rwxr-xr-x`)

### 3. Test Hook Validation

**Test invalid formats (should FAIL ❌):**

```bash
git commit --allow-empty -m "Added feature"              # Missing type
git commit --allow-empty -m "fix bug"                    # Missing colon
git commit --allow-empty -m "update: something"          # Invalid type
git commit --allow-empty -m "feat: add feature."         # Period at end
```

**Test valid formats (should PASS ✅):**

```bash
git commit --allow-empty -m "feat: add feature"
git commit --allow-empty -m "fix(ping): resolve bug"
git commit --allow-empty -m "feat!(api): breaking change"
git commit --allow-empty -m "docs: update readme"
```

### 4. Make Initial Commit

- [ ] Stage all files: `git add .`
- [ ] Create initial commit: `git commit -m "chore: initial commit"`
- [ ] Verify commit: `git log --oneline -1`
- [ ] Expected output: `<hash> chore: initial commit`

### 5. Verify Setup Complete

- [ ] Hook validates commits (test with invalid message)
- [ ] All files committed: `git status` shows "working tree clean"
- [ ] `.env` not tracked: `git ls-files | grep -q "^\.env$" && echo "ERROR" || echo "OK"`
- [ ] Gemfile.lock tracked: `git ls-files | grep -q "Gemfile.lock" && echo "OK"`

### Troubleshooting

**Hook not rejecting invalid commits:**

```bash
# Check hook exists and is executable
ls -l .git/hooks/commit-msg

# Make executable if needed
chmod +x .git/hooks/commit-msg

# Test hook directly
echo "invalid message" | .git/hooks/commit-msg /dev/stdin

# Reinstall
./git-hooks/install.sh
```

**Hook installed but git not using it:**

```bash
# Check git hooks path
git config core.hooksPath
# Should be empty (uses default .git/hooks)

# If set to something else, reset to default
git config --unset core.hooksPath
```

**Want to bypass hook temporarily:**

```bash
# Emergency only - not for PRs
git commit --no-verify -m "WIP: temp commit"
```

### Reference

- **Conventional Commits:** https://www.conventionalcommits.org/en/v1.0.0/
- **Complete guidelines:** `CONTRIBUTING.md`
- **Hook documentation:** `.git-hooks/README.md`

---

## Resources

- **Slack API Docs**: https://api.slack.com/
- **Deployment Guides**: See `IMPLEMENTATION.md` section 7
- **Logging Details**: See `IMPLEMENTATION.md` section 6
- **Testing Checklist**: See `IMPLEMENTATION.md` section 8

---

**Last Updated:** December 23, 2025  
**Status:** Implementation complete, awaiting git setup and Slack app configuration
