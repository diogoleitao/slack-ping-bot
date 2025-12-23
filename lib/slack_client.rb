# frozen_string_literal: true

require "slack-ruby-client"
require "ougai"

class SlackClient
  USERS_CACHE_TTL = 300 # 5 minutes

  def initialize(token, logger: Ougai::Logger.new($stdout))
    @logger = logger
    Slack.configure do |config|
      config.token = token
    end
    @client = Slack::Web::Client.new
    @users_cache = nil
    @users_cache_time = nil
  end

  # Post message to channel/DM, returns timestamp for deletion
  def post_message(channel, text)
    response = @client.chat_postMessage(
      channel: channel,
      text: text
    )
    response["ts"]
  rescue Slack::Web::Api::Errors::SlackError => e
    @logger.error("Failed to post message", error: e.message, channel: channel)
    raise
  end

  # Delete message by channel and timestamp
  def delete_message(channel, timestamp)
    @client.chat_delete(
      channel: channel,
      ts: timestamp
    )
  rescue Slack::Web::Api::Errors::SlackError => e
    @logger.error("Failed to delete message", error: e.message, channel: channel, timestamp: timestamp)
    raise
  end

  # Open DM channel with user, returns channel ID
  def open_dm(user_id)
    response = @client.conversations_open(users: user_id)
    response["channel"]["id"]
  rescue Slack::Web::Api::Errors::SlackError => e
    @logger.error("Failed to open DM", error: e.message, user_id: user_id)
    raise
  end

  # Get user by exact name match (case-insensitive)
  def get_user_by_name(name)
    users = fetch_users
    name_lower = name.downcase

    users.find do |user|
      user_name = user["name"]&.downcase
      display_name = user.dig("profile", "display_name")&.downcase
      real_name = user.dig("profile", "real_name")&.downcase

      user_name == name_lower || 
        display_name == name_lower || 
        real_name == name_lower
    end
  end

  # Get user by ID
  def get_user_by_id(user_id)
    @client.users_info(user: user_id)["user"]
  rescue Slack::Web::Api::Errors::SlackError => e
    @logger.error("Failed to get user info", error: e.message, user_id: user_id)
    nil
  end

  private

  # Fetch all users with caching
  def fetch_users
    now = Time.now.to_i

    # Return cached users if fresh
    if @users_cache && @users_cache_time && (now - @users_cache_time) < USERS_CACHE_TTL
      return @users_cache
    end

    # Fetch fresh user list
    @logger.info("Fetching user list from Slack API")
    response = @client.users_list
    @users_cache = response["members"]
    @users_cache_time = now
    @users_cache
  rescue Slack::Web::Api::Errors::SlackError => e
    @logger.error("Failed to fetch users", error: e.message)
    @users_cache || []
  end
end
