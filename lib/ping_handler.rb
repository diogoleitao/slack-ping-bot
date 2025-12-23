# frozen_string_literal: true

require_relative 'user_resolver'
require 'ougai'

module PingHandler
  DELETION_DELAY_MS = 150

  def self.execute(sender_id:, channel_id:, text:, slack_client:, rate_limiter:, logger: Ougai::Logger.new($stdout))
    resolution = UserResolver.resolve(channel_id, text, sender_id, slack_client)

    return { success: false, error: resolution[:error] } if resolution[:error]

    target_user_id = resolution[:user_id]

    unless rate_limiter.check_and_increment(sender_id)
      return {
        success: false,
        error: 'Rate limit exceeded. Maximum 3 pings per minute.'
      }
    end

    dm_channel = if target_user_id.start_with?('D')
                   target_user_id
                 else
                   slack_client.open_dm(target_user_id)
                 end

    message_text = "👋 Ping from <@#{sender_id}>"
    timestamp = slack_client.post_message(dm_channel, message_text)

    logger.info('Sent ping', channel: dm_channel, timestamp: timestamp, target_user_id: target_user_id)

    sleep(DELETION_DELAY_MS / 1000.0)

    slack_client.delete_message(dm_channel, timestamp)

    logger.info('Deleted ping message', channel: dm_channel, timestamp: timestamp, delay_ms: DELETION_DELAY_MS)

    {
      success: true,
      message: "Pinged <@#{target_user_id}>"
    }
  rescue Slack::Web::Api::Errors::ChannelNotFound
    { success: false, error: 'Cannot send DM to user. They may have DMs disabled.' }
  rescue Slack::Web::Api::Errors::UserNotFound
    { success: false, error: 'User not found.' }
  rescue Slack::Web::Api::Errors::AccountInactive
    { success: false, error: 'Cannot ping deactivated users.' }
  rescue Slack::Web::Api::Errors::SlackError => e
    logger.error('Slack API error', error: e.message, error_class: e.class.name)
    { success: false, error: 'Failed to send ping. Please try again.' }
  rescue StandardError => e
    logger.error('Unexpected error in PingHandler', error_class: e.class.name, error: e.message,
                                                    backtrace: e.backtrace.first(5))
    { success: false, error: 'Failed to send ping. Please try again.' }
  end
end
