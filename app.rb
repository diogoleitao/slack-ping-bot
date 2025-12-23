# frozen_string_literal: true

require "sinatra"
require "json"
require "dotenv/load"
require "ougai"

require_relative "lib/version"
require_relative "lib/slack_verifier"
require_relative "lib/slack_client"
require_relative "lib/rate_limiter"
require_relative "lib/user_resolver"
require_relative "lib/ping_handler"

# Configure Sinatra
set :port, ENV.fetch("PORT", 4567)
set :bind, "0.0.0.0"
set :logging, true

# Initialize logger
logger = Ougai::Logger.new($stdout)
logger.level = ENV.fetch("LOG_LEVEL", "info").downcase.to_sym

# Initialize components
slack_client = SlackClient.new(ENV.fetch("SLACK_BOT_TOKEN"), logger: logger)
rate_limiter = RateLimiter.new(ENV.fetch("REDIS_URL", "redis://localhost:6379/0"), logger: logger)

# Health check endpoint
get "/" do
  content_type :json
  { status: "ok", service: "slack-ping-bot" }.to_json
end

# Version endpoint
get "/version" do
  content_type :json
  {
    version: SlackPingBot::VERSION,
    commit_sha: SlackPingBot::BUILD_SHA,
    build_date: SlackPingBot::BUILD_DATE
  }.to_json
end

# Slack slash command endpoint
post "/slack/commands" do
  content_type :json

  # Verify request signature
  unless SlackVerifier.valid?(request, ENV.fetch("SLACK_SIGNING_SECRET"), logger: logger)
    halt 401, { error: "Invalid signature" }.to_json
  end

  # Parse Slack payload
  sender_id = params[:user_id]
  channel_id = params[:channel_id]
  text = params[:text]&.strip || ""

  logger.info("Received /ping command", user_id: sender_id, channel_id: channel_id, text: text)

  # Execute ping
  result = PingHandler.execute(
    sender_id: sender_id,
    channel_id: channel_id,
    text: text,
    slack_client: slack_client,
    rate_limiter: rate_limiter,
    logger: logger
  )

  # Return response
  if result[:success]
    logger.info("Ping successful", message: result[:message])
    {
      response_type: "ephemeral",
      text: result[:message]
    }.to_json
  else
    logger.warn("Ping failed", error: result[:error])
    {
      response_type: "ephemeral",
      text: result[:error]
    }.to_json
  end
rescue => e
  logger.error("Unexpected error", error_class: e.class.name, error: e.message, backtrace: e.backtrace.first(5))
  
  {
    response_type: "ephemeral",
    text: "Failed to send ping. Please try again."
  }.to_json
end

# Error handlers
error 401 do
  content_type :json
  { error: "Unauthorized" }.to_json
end

error 500 do
  content_type :json
  { error: "Internal server error" }.to_json
end
