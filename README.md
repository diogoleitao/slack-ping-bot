# Slack Ping Bot

A high-performance Slack bot that sends notification pings without persistent messages.

## Features

- **Ping users via DM**: Use `/ping` in a direct message
- **Ping users in channels**: Use `/ping @username` in any channel
- **High Performance**: Built on Ruby 3.4 with YJIT for 15-25% speed boost
- **Rate limiting**: Maximum 3 pings per minute per user
- **No message clutter**: Messages automatically deleted after 150ms
- **Notification persists**: Target user receives notification even after deletion
- **Security**: Request signature verification prevents unauthorized access
- **Resilient**: Falls back to in-memory rate limiting if Redis unavailable

## How It Works

1. User sends `/ping` command
2. Bot validates target user
3. Bot checks rate limits (Redis-backed)
4. Bot sends DM: "👋 Ping from @sender"
5. Bot deletes message after 150ms
6. Target user receives notification

## Requirements

- **Ruby 3.4.x** (latest stable: 3.4.8)
  - Minimum: Ruby 3.0
  - Recommended: Ruby 3.4.8 with YJIT
- **Redis** (optional, for distributed rate limiting)
- **Slack workspace** with permissions to install apps

## Technology Stack

- Ruby 3.4 with YJIT (Just-In-Time compiler)
- Sinatra 4.2 (web framework)
- Puma 7.1 (web server)
- Redis 5.4 (rate limiting)
- slack-ruby-client 3.1 (Slack API)
- Ougai 2.0 (structured JSON logging)

## Installation

### 1. Create Slack App

1. Go to https://api.slack.com/apps
2. Click "Create New App" → "From scratch"
3. Name your app (e.g., "Ping Bot") and select your workspace
4. Navigate to **OAuth & Permissions**:
   - Add Bot Token Scopes:
     - `chat:write`
     - `users:read`
     - `im:write`
     - `commands`
   - Install app to workspace
   - Copy the **Bot User OAuth Token** (starts with `xoxb-`)
5. Navigate to **Slash Commands**:
   - Click "Create New Command"
   - Command: `/ping`
   - Request URL: `https://your-domain.com/slack/commands`
   - Short Description: "Ping a user"
   - Usage Hint: `[@username]`
   - Save
6. Navigate to **Basic Information**:
   - Copy the **Signing Secret** under "App Credentials"

### 2. Clone and Setup

```bash
# Clone repository
git clone <your-repo-url>
cd slack-ping-bot

# Install Ruby 3.4 (using rbenv recommended)
rbenv install 3.4.8
rbenv local 3.4.8

# Install dependencies
bundle install

# Configure environment
cp .env.example .env
# Edit .env with your Slack credentials
```

### 3. Configure Environment Variables

Edit `.env`:

```bash
SLACK_BOT_TOKEN=xoxb-your-actual-token
SLACK_SIGNING_SECRET=your-actual-signing-secret
REDIS_URL=redis://localhost:6379/0
PORT=4567
RUBY_YJIT_ENABLE=1  # Enable performance boost
```

### 4. Start Redis (Optional but Recommended)

```bash
# Using Docker
docker run -d -p 6379:6379 redis:alpine

# Or install locally (macOS)
brew install redis
redis-server

# Or use Docker Compose (includes app + redis)
docker-compose up -d
```

### 5. Run Locally

```bash
# Development mode with auto-reload
bundle exec rerun 'rackup -p 4567'

# Or production mode with YJIT
RUBY_YJIT_ENABLE=1 bundle exec puma -C config/puma.rb
```

### 6. Expose Locally with ngrok

```bash
# Install ngrok: https://ngrok.com/
ngrok http 4567

# Copy the HTTPS URL (e.g., https://abc123.ngrok.io)
```

### 7. Update Slack App Configuration

1. Go back to your Slack App settings
2. Navigate to **Slash Commands**
3. Edit `/ping` command
4. Update Request URL to: `https://your-ngrok-url.ngrok.io/slack/commands`
5. Save changes

### 8. Test in Slack

- In any channel: `/ping @username`
- In a DM: `/ping`

## Docker Deployment

### Build Image

```bash
docker build -t slack-ping-bot .
```

### Run with Docker Compose

```bash
# Includes Redis + App with YJIT enabled
docker-compose up -d
```

### Run Standalone Container

```bash
docker run -d \
  -p 4567:4567 \
  -e SLACK_BOT_TOKEN=xoxb-... \
  -e SLACK_SIGNING_SECRET=... \
  -e REDIS_URL=redis://your-redis:6379/0 \
  -e RUBY_YJIT_ENABLE=1 \
  slack-ping-bot
```

## Deployment Options

### Heroku

```bash
# Create app
heroku create your-ping-bot

# Set Ruby version (create .ruby-version file)
echo "3.4.8" > .ruby-version

# Add Redis
heroku addons:create heroku-redis:mini

# Set environment variables
heroku config:set SLACK_BOT_TOKEN=xoxb-...
heroku config:set SLACK_SIGNING_SECRET=...
heroku config:set RUBY_YJIT_ENABLE=1

# Deploy
git push heroku main

# Update Slack slash command URL to:
# https://your-ping-bot.herokuapp.com/slack/commands
```

### Fly.io

```bash
# Install flyctl: https://fly.io/docs/hands-on/install-flyctl/

# Launch app
fly launch

# Set secrets
fly secrets set SLACK_BOT_TOKEN=xoxb-...
fly secrets set SLACK_SIGNING_SECRET=...
fly secrets set RUBY_YJIT_ENABLE=1

# Deploy
fly deploy
```

### Railway

1. Connect GitHub repository to Railway
2. Add Redis plugin
3. Set environment variables in Railway dashboard:
   - `SLACK_BOT_TOKEN`
   - `SLACK_SIGNING_SECRET`
   - `RUBY_YJIT_ENABLE=1`
4. Deploy automatically on push

## Usage

### In Direct Messages

```
/ping
```

Sends a ping to the person you're DMing with.

### In Channels

```
/ping @username
```

Sends a ping to the specified user. Supports:
- Display names: `/ping @john.doe`
- Slack user IDs: `/ping <@U12345>`

## Error Messages

All error messages are ephemeral (only visible to command sender):

- **User not found**: Username doesn't match exactly
- **Cannot ping yourself**: Self-pinging is disabled
- **Cannot ping bots**: Bot users cannot be pinged
- **Cannot ping deactivated users**: Inactive accounts cannot be pinged
- **Rate limit exceeded**: Maximum 3 pings per minute
- **Cannot send DM**: User may have DMs disabled

## Rate Limiting

- **Limit**: 3 pings per minute per sender
- **Window**: Rolling 60-second window
- **Scope**: Per-sender only (no limits on receiving pings)
- **Storage**: Redis (with in-memory fallback)

## Security

- **Request verification**: All Slack requests verified via HMAC-SHA256
- **Replay protection**: Requests older than 5 minutes rejected
- **No data storage**: No messages or pings are logged
- **Ephemeral responses**: Error messages only visible to sender

## Logging

Structured JSON logging via [Ougai](https://github.com/tilfin/ougai). Compatible with Datadog, CloudWatch, Splunk, ELK Stack.

Configure log level:
```bash
LOG_LEVEL=info  # Options: trace, debug, info, warn, error, fatal
```

See [`docs/IMPLEMENTATION.md`](docs/IMPLEMENTATION.md#6-logging-implementation) for advanced configuration and integration examples.

## Performance

Uses Ruby 3.4's **YJIT** (Just-In-Time compiler) for 15-25% faster request processing.

Enable YJIT by setting `RUBY_YJIT_ENABLE=1` in your environment (included in `.env.example`).

## Troubleshooting

### Bot not responding

1. Check Slack app slash command URL is correct
2. Verify environment variables are set correctly
3. Check server logs for errors
4. Test health endpoint: `curl https://your-domain.com/`

### "Invalid signature" errors

- Verify `SLACK_SIGNING_SECRET` matches your Slack app
- Check server time is synchronized (for timestamp validation)

### Rate limiting not working

- Verify Redis is running and accessible
- Check Redis connection URL
- Bot will fall back to in-memory rate limiting if Redis fails

### User not found errors

- Username must match exactly (case-insensitive)
- Try using Slack's user ID format: `/ping <@U12345>`
- User may be deactivated

### YJIT not working

```bash
# Check if YJIT is enabled
ruby --yjit -e "puts RubyVM::YJIT.enabled?"
# Should output: true

# Verify environment variable
echo $RUBY_YJIT_ENABLE
# Should output: 1
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for contribution guidelines including:
- Conventional Commits format
- Git hooks setup
- Code style guidelines
- Pull request process

## Versioning

This project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**Current version:** `0.1.0` (pre-production)

Check version:
```bash
# Via file
cat VERSION

# Via Ruby
ruby -r ./lib/version -e "puts SlackPingBot.version_string"

# Via API (when running)
curl http://localhost:4567/version
```

**Version history:** See [CHANGELOG.md](CHANGELOG.md)  
**Releases:** See [GitHub Releases](https://github.com/diogoleitao/slack-ping-bot/releases)

## License

MIT License

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review server logs for error details
3. Open an issue on GitHub

## Credits

Built with:
- Ruby 3.4 with YJIT
- Sinatra 4.2 web framework
- slack-ruby-client 3.1
- Redis 5.4 for rate limiting
- Puma 7.1 web server
- Docker for containerization
