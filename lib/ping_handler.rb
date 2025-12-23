# frozen_string_literal: true

require_relative "user_resolver"
require "ougai"

module PingHandler
  DELETION_DELAY_MS = 150 # milliseconds (middle of 100-200ms range)

  def self.execute(sender_id:, channel_id:, text:, slack_client:, rate_limiter:, logger: Ougai::Logger.new($stdout))
    # Step 1: Resolve target user
    resolution = UserResolver.resolve(channel_id, text, sender_id, slack_client)
    
    if resolution[:error]
      return { success: false, error: resolution[:error] }
    end

    target_user_id = resolution[:user_id]

    # Step 2: Check rate limit
    unless rate_limiter.check_and_increment(sender_id)
      return { 
        success: false, 
        error: "Rate limit exceeded. Maximum 3 pings per minute." 
      }
    end

    # Step 3: Open DM with target (if not already a DM channel)
    dm_channel = if target_user_id.start_with?("D")
                   # Already a DM channel
                   target_user_id
                 else
                   # Open DM with user
                   slack_client.open_dm(target_user_id)
                 end

    # Step 4: Send ping message
    message_text = "👋 Ping from <@#{sender_id}>"
    timestamp = slack_client.post_message(dm_channel, message_text)

    logger.info("Sent ping", channel: dm_channel, timestamp: timestamp, target_user_id: target_user_id)

    # Step 5: Wait before deletion (100-200ms)
    sleep(DELETION_DELAY_MS / 1000.0)

    # Step 6: Delete message
    slack_client.delete_message(dm_channel, timestamp)

    logger.info("Deleted ping message", channel: dm_channel, timestamp: timestamp, delay_ms: DELETION_DELAY_MS)

    # Step 7: Return success
    { 
      success: true, 
      message: "Pinged <@#{target_user_id}>" 
    }

  rescue Slack::Web::Api::Errors::ChannelNotFound
    { success: false, error: "Cannot send DM to user. They may have DMs disabled." }
  rescue Slack::Web::Api::Errors::UserNotFound
    { success: false, error: "User not found." }
  rescue Slack::Web::Api::Errors::AccountInactive
    { success: false, error: "Cannot ping deactivated users." }
  rescue Slack::Web::Api::Errors::SlackError => e
    logger.error("Slack API error", error: e.message, error_class: e.class.name)
    { success: false, error: "Failed to send ping. Please try again." }
  rescue => e
    logger.error("Unexpected error in PingHandler", error_class: e.class.name, error: e.message, backtrace: e.backtrace.first(5))
    { success: false, error: "Failed to send ping. Please try again." }
  end
end
