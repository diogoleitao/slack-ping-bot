# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Changelog format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- Semantic versioning support with VERSION file and lib/version.rb
- CHANGELOG.md for tracking project changes
- Version API endpoint at GET /version
- Build metadata tracking (commit SHA and build date)
- Comprehensive versioning documentation

## [0.1.0] - 2025-12-23

### Added
- Initial implementation of Slack Ping Bot
- Ephemeral ping functionality with 150ms message deletion
- `/ping` slash command for DMs and channel mentions
- Rate limiting: 3 pings per minute per sender
- Redis-backed rate limiter with thread-safe in-memory fallback
- User validation and mention parsing (@username and <@U123> formats)
- HMAC-SHA256 request signature verification for security
- Structured JSON logging with Ougai
- User caching (5-minute TTL) to reduce Slack API calls
- Docker support with YJIT enabled
- Conventional commits enforcement via git hooks
- Comprehensive documentation:
  - README.md (user guide)
  - docs/IMPLEMENTATION.md (technical details)
  - docs/TODO.md (roadmap and testing checklist)
  - CLAUDE.md (AI assistant context)
  - CONTRIBUTING.md (contribution guidelines)
  - .git-hooks/ (commit message validation)

### Security
- Request signature validation prevents unauthorized access
- Replay attack protection (reject requests >5min old)
- Constant-time signature comparison
- No data persistence (privacy by design)

### Performance
- Ruby 3.4.8 with YJIT (15-25% performance boost)
- User list caching reduces API calls
- Efficient Redis operations with fallback

[Unreleased]: https://github.com/diogoleitao/slack-ping-bot/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/diogoleitao/slack-ping-bot/releases/tag/v0.1.0
