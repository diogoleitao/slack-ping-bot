# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/ping_handler'

RSpec.describe PingHandler do
  let(:sender_id) { 'U123' }
  let(:target_user_id) { 'U456' }
  let(:channel_id) { 'C789' }
  let(:dm_channel_id) { 'D321' }
  let(:text) { '@targetuser' }
  let(:timestamp) { '1234567890.123456' }

  let(:slack_client) { instance_double(SlackClient) }
  let(:rate_limiter) { instance_double(RateLimiter) }
  let(:logger) { instance_double(Ougai::Logger, info: nil, error: nil) }

  describe '.execute' do
    before do
      allow(UserResolver).to receive(:resolve).and_return({ user_id: target_user_id })
      allow(rate_limiter).to receive(:check_and_increment).with(sender_id).and_return(true)
      allow(slack_client).to receive(:open_dm).with(target_user_id).and_return(dm_channel_id)
      allow(slack_client).to receive(:post_message).with(dm_channel_id,
                                                         "👋 Ping from <@#{sender_id}>").and_return(timestamp)
      allow(slack_client).to receive(:delete_message).with(dm_channel_id, timestamp)
    end

    context 'with successful ping' do
      it 'sends and deletes message' do
        result = described_class.execute(
          sender_id: sender_id,
          channel_id: channel_id,
          text: text,
          slack_client: slack_client,
          rate_limiter: rate_limiter,
          logger: logger
        )

        expect(result).to eq({ success: true, message: "Pinged <@#{target_user_id}>" })
        expect(slack_client).to have_received(:post_message)
        expect(slack_client).to have_received(:delete_message)
      end

      it 'logs ping events' do
        expect(logger).to receive(:info).with('Sent ping', channel: dm_channel_id, timestamp: timestamp,
                                                           target_user_id: target_user_id)
        expect(logger).to receive(:info).with('Deleted ping message', channel: dm_channel_id, timestamp: timestamp,
                                                                      delay_ms: 150)

        described_class.execute(
          sender_id: sender_id,
          channel_id: channel_id,
          text: text,
          slack_client: slack_client,
          rate_limiter: rate_limiter,
          logger: logger
        )
      end

      it 'waits 150ms before deleting' do
        expect(described_class).to receive(:sleep).with(0.15)

        described_class.execute(
          sender_id: sender_id,
          channel_id: channel_id,
          text: text,
          slack_client: slack_client,
          rate_limiter: rate_limiter,
          logger: logger
        )
      end
    end

    context 'with DM channel (starts with D)' do
      it 'uses channel directly without opening DM' do
        allow(UserResolver).to receive(:resolve).and_return({ user_id: dm_channel_id })
        allow(slack_client).to receive(:post_message).with(dm_channel_id,
                                                           "👋 Ping from <@#{sender_id}>").and_return(timestamp)

        described_class.execute(
          sender_id: sender_id,
          channel_id: channel_id,
          text: '',
          slack_client: slack_client,
          rate_limiter: rate_limiter,
          logger: logger
        )

        expect(slack_client).not_to have_received(:open_dm)
      end
    end

    context 'when user resolution fails' do
      it 'returns error' do
        allow(UserResolver).to receive(:resolve).and_return({ error: 'User not found' })

        result = described_class.execute(
          sender_id: sender_id,
          channel_id: channel_id,
          text: text,
          slack_client: slack_client,
          rate_limiter: rate_limiter,
          logger: logger
        )

        expect(result).to eq({ success: false, error: 'User not found' })
        expect(slack_client).not_to have_received(:post_message)
      end
    end

    context 'when rate limit exceeded' do
      it 'returns error' do
        allow(rate_limiter).to receive(:check_and_increment).with(sender_id).and_return(false)

        result = described_class.execute(
          sender_id: sender_id,
          channel_id: channel_id,
          text: text,
          slack_client: slack_client,
          rate_limiter: rate_limiter,
          logger: logger
        )

        expect(result).to eq({ success: false, error: 'Rate limit exceeded. Maximum 3 pings per minute.' })
        expect(slack_client).not_to have_received(:post_message)
      end
    end

    context 'with Slack API errors' do
      it 'handles ChannelNotFound' do
        allow(slack_client).to receive(:open_dm).and_raise(Slack::Web::Api::Errors::ChannelNotFound.new('not_found'))

        result = described_class.execute(
          sender_id: sender_id,
          channel_id: channel_id,
          text: text,
          slack_client: slack_client,
          rate_limiter: rate_limiter,
          logger: logger
        )

        expect(result).to eq({ success: false, error: 'Cannot send DM to user. They may have DMs disabled.' })
      end

      it 'handles UserNotFound' do
        allow(slack_client).to receive(:open_dm).and_raise(Slack::Web::Api::Errors::UserNotFound.new('not_found'))

        result = described_class.execute(
          sender_id: sender_id,
          channel_id: channel_id,
          text: text,
          slack_client: slack_client,
          rate_limiter: rate_limiter,
          logger: logger
        )

        expect(result).to eq({ success: false, error: 'User not found.' })
      end

      it 'handles AccountInactive' do
        allow(slack_client).to receive(:open_dm).and_raise(Slack::Web::Api::Errors::AccountInactive.new('inactive'))

        result = described_class.execute(
          sender_id: sender_id,
          channel_id: channel_id,
          text: text,
          slack_client: slack_client,
          rate_limiter: rate_limiter,
          logger: logger
        )

        expect(result).to eq({ success: false, error: 'Cannot ping deactivated users.' })
      end

      it 'handles generic SlackError' do
        allow(slack_client).to receive(:open_dm).and_raise(Slack::Web::Api::Errors::SlackError.new('api_error'))

        expect(logger).to receive(:error).with('Slack API error', hash_including(error: 'api_error'))

        result = described_class.execute(
          sender_id: sender_id,
          channel_id: channel_id,
          text: text,
          slack_client: slack_client,
          rate_limiter: rate_limiter,
          logger: logger
        )

        expect(result).to eq({ success: false, error: 'Failed to send ping. Please try again.' })
      end
    end

    context 'with unexpected errors' do
      it 'handles StandardError' do
        allow(slack_client).to receive(:open_dm).and_raise(StandardError, 'unexpected')

        expect(logger).to receive(:error).with(
          'Unexpected error in PingHandler',
          hash_including(error_class: 'StandardError', error: 'unexpected')
        )

        result = described_class.execute(
          sender_id: sender_id,
          channel_id: channel_id,
          text: text,
          slack_client: slack_client,
          rate_limiter: rate_limiter,
          logger: logger
        )

        expect(result).to eq({ success: false, error: 'Failed to send ping. Please try again.' })
      end
    end
  end
end
