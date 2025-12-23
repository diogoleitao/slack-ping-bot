# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/slack_client'

RSpec.describe SlackClient do
  let(:token) { ENV.fetch('SLACK_BOT_TOKEN', 'xoxb-test-token') }
  let(:logger) { instance_double(Ougai::Logger, info: nil, error: nil) }
  let(:web_client) { instance_double(Slack::Web::Client) }
  let(:slack_client) do
    allow(Slack::Web::Client).to receive(:new).and_return(web_client)
    described_class.new(token, logger: logger)
  end

  describe '#post_message' do
    it 'posts message and returns timestamp' do
      allow(web_client).to receive(:chat_postMessage).with(
        channel: 'C123',
        text: 'Hello'
      ).and_return({ 'ts' => '1234567890.123456' })

      result = slack_client.post_message('C123', 'Hello')
      expect(result).to eq('1234567890.123456')
    end

    it 'logs error and raises on failure' do
      allow(web_client).to receive(:chat_postMessage).and_raise(
        Slack::Web::Api::Errors::ChannelNotFound.new('channel_not_found')
      )

      expect(logger).to receive(:error).with(
        'Failed to post message',
        hash_including(error: 'channel_not_found', channel: 'C123')
      )

      expect do
        slack_client.post_message('C123', 'Hello')
      end.to raise_error(Slack::Web::Api::Errors::ChannelNotFound)
    end
  end

  describe '#delete_message' do
    it 'deletes message successfully' do
      allow(web_client).to receive(:chat_delete).with(
        channel: 'C123',
        ts: '1234567890.123456'
      ).and_return({ 'ok' => true })

      expect { slack_client.delete_message('C123', '1234567890.123456') }.not_to raise_error
    end

    it 'logs error and raises on failure' do
      allow(web_client).to receive(:chat_delete).and_raise(
        Slack::Web::Api::Errors::MessageNotFound.new('message_not_found')
      )

      expect(logger).to receive(:error).with(
        'Failed to delete message',
        hash_including(error: 'message_not_found', channel: 'C123', timestamp: '1234567890.123456')
      )

      expect do
        slack_client.delete_message('C123', '1234567890.123456')
      end.to raise_error(Slack::Web::Api::Errors::MessageNotFound)
    end
  end

  describe '#open_dm' do
    it 'opens DM and returns channel ID' do
      allow(web_client).to receive(:conversations_open).with(users: 'U123').and_return(
        { 'channel' => { 'id' => 'D456' } }
      )

      result = slack_client.open_dm('U123')
      expect(result).to eq('D456')
    end

    it 'logs error and raises on failure' do
      allow(web_client).to receive(:conversations_open).and_raise(
        Slack::Web::Api::Errors::UserNotFound.new('user_not_found')
      )

      expect(logger).to receive(:error).with(
        'Failed to open DM',
        hash_including(error: 'user_not_found', user_id: 'U123')
      )

      expect do
        slack_client.open_dm('U123')
      end.to raise_error(Slack::Web::Api::Errors::UserNotFound)
    end
  end

  describe '#get_user_by_name' do
    let(:users) do
      [
        { 'id' => 'U1', 'name' => 'john', 'profile' => { 'display_name' => 'Johnny', 'real_name' => 'John Doe' } },
        { 'id' => 'U2', 'name' => 'jane', 'profile' => { 'display_name' => 'Janey', 'real_name' => 'Jane Smith' } }
      ]
    end

    before do
      allow(web_client).to receive(:users_list).and_return(
        { 'members' => users, 'cache_ts' => Time.now.to_i }
      )
      allow(logger).to receive(:info).with('Fetching user list from Slack API')
    end

    it 'finds user by exact username' do
      result = slack_client.get_user_by_name('john')
      expect(result['id']).to eq('U1')
    end

    it 'finds user by display name' do
      result = slack_client.get_user_by_name('Johnny')
      expect(result['id']).to eq('U1')
    end

    it 'finds user by real name' do
      result = slack_client.get_user_by_name('Jane Smith')
      expect(result['id']).to eq('U2')
    end

    it 'is case insensitive' do
      result = slack_client.get_user_by_name('JOHN')
      expect(result['id']).to eq('U1')
    end

    it 'returns nil when user not found' do
      result = slack_client.get_user_by_name('nonexistent')
      expect(result).to be_nil
    end
  end

  describe '#get_user_by_id' do
    it 'fetches user info by ID' do
      allow(web_client).to receive(:users_info).with(user: 'U123').and_return(
        { 'user' => { 'id' => 'U123', 'name' => 'john' } }
      )

      result = slack_client.get_user_by_id('U123')
      expect(result['id']).to eq('U123')
    end

    it 'returns nil on error' do
      allow(web_client).to receive(:users_info).and_raise(
        Slack::Web::Api::Errors::UserNotFound.new('user_not_found')
      )

      expect(logger).to receive(:error).with(
        'Failed to get user info',
        hash_including(error: 'user_not_found', user_id: 'U999')
      )

      result = slack_client.get_user_by_id('U999')
      expect(result).to be_nil
    end
  end

  describe 'user caching' do
    let(:users) do
      [
        { 'id' => 'U1', 'name' => 'john', 'profile' => { 'display_name' => '', 'real_name' => 'John Doe' } }
      ]
    end

    before do
      allow(web_client).to receive(:users_list).and_return(
        { 'members' => users, 'cache_ts' => Time.now.to_i }
      )
    end

    it 'caches users for TTL duration' do
      expect(logger).to receive(:info).with('Fetching user list from Slack API').once

      slack_client.get_user_by_name('john')
      slack_client.get_user_by_name('john')
    end

    it 'refreshes cache after TTL expires' do
      expect(logger).to receive(:info).with('Fetching user list from Slack API').twice

      slack_client.get_user_by_name('john')

      Timecop.travel(Time.now + 301) do
        slack_client.get_user_by_name('john')
      end
    end

    it 'returns empty array on fetch error' do
      allow(web_client).to receive(:users_list).and_raise(
        Slack::Web::Api::Errors::SlackError.new('API error')
      )

      expect(logger).to receive(:info).with('Fetching user list from Slack API')
      expect(logger).to receive(:error).with(
        'Failed to fetch users',
        hash_including(error: 'API error')
      )

      result = slack_client.get_user_by_name('john')
      expect(result).to be_nil
    end
  end
end
