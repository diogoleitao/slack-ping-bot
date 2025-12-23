# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/user_resolver'

RSpec.describe UserResolver do
  let(:fixtures) { load_fixture('users') }
  let(:active_user) { JSON.parse(fixtures[:active_user].to_json) }
  let(:another_user) { JSON.parse(fixtures[:another_user].to_json) }
  let(:bot_user) { JSON.parse(fixtures[:bot_user].to_json) }
  let(:deactivated_user) { JSON.parse(fixtures[:deactivated_user].to_json) }

  let(:sender_id) { active_user['id'] }
  let(:channel_id) { 'C123456' }
  let(:dm_channel_id) { 'D987654' }
  let(:slack_client) { instance_double(SlackClient) }

  describe '.resolve' do
    context 'with empty text (DM ping)' do
      context 'in DM channel' do
        it 'returns DM channel ID' do
          result = described_class.resolve(dm_channel_id, '', sender_id, slack_client)
          expect(result).to eq({ user_id: dm_channel_id })
        end
      end

      context 'in regular channel' do
        it 'returns usage error' do
          result = described_class.resolve(channel_id, '', sender_id, slack_client)
          expect(result).to eq({ error: 'Usage: /ping @username (in channel) or /ping (in DM)' })
        end
      end
    end

    context 'with user mention' do
      it 'resolves valid username mention' do
        allow(slack_client).to receive(:get_user_by_name).with('janedoe').and_return(another_user)
        allow(slack_client).to receive(:get_user_by_id).with(another_user['id']).and_return(another_user)

        result = described_class.resolve(channel_id, '@janedoe', sender_id, slack_client)
        expect(result).to eq({ user_id: another_user['id'] })
      end

      it 'resolves valid user ID mention' do
        allow(slack_client).to receive(:get_user_by_id).with(another_user['id']).and_return(another_user)

        result = described_class.resolve(channel_id, "<@#{another_user["id"]}>", sender_id, slack_client)
        expect(result).to eq({ user_id: another_user['id'] })
      end
    end
  end

  describe '.resolve_mention' do
    context 'with user ID format' do
      it 'resolves <@U123>' do
        allow(slack_client).to receive(:get_user_by_id).with(another_user['id']).and_return(another_user)

        result = described_class.resolve_mention("<@#{another_user["id"]}>", sender_id, slack_client)
        expect(result).to eq({ user_id: another_user['id'] })
      end

      it 'resolves <@U123|username>' do
        allow(slack_client).to receive(:get_user_by_id).with(another_user['id']).and_return(another_user)

        result = described_class.resolve_mention("<@#{another_user["id"]}|janedoe>", sender_id, slack_client)
        expect(result).to eq({ user_id: another_user['id'] })
      end
    end

    context 'with username format' do
      it 'resolves @username' do
        allow(slack_client).to receive(:get_user_by_name).with('janedoe').and_return(another_user)
        allow(slack_client).to receive(:get_user_by_id).with(another_user['id']).and_return(another_user)

        result = described_class.resolve_mention('@janedoe', sender_id, slack_client)
        expect(result).to eq({ user_id: another_user['id'] })
      end

      it 'resolves username without @' do
        allow(slack_client).to receive(:get_user_by_name).with('janedoe').and_return(another_user)
        allow(slack_client).to receive(:get_user_by_id).with(another_user['id']).and_return(another_user)

        result = described_class.resolve_mention('janedoe', sender_id, slack_client)
        expect(result).to eq({ user_id: another_user['id'] })
      end
    end

    context 'with invalid format' do
      it 'returns error for multiple words' do
        result = described_class.resolve_mention('hello world', sender_id, slack_client)
        expect(result).to eq({ error: 'Invalid format. Usage: /ping @username' })
      end
    end
  end

  describe '.resolve_username' do
    context 'with valid username' do
      it 'resolves user' do
        allow(slack_client).to receive(:get_user_by_name).with('janedoe').and_return(another_user)
        allow(slack_client).to receive(:get_user_by_id).with(another_user['id']).and_return(another_user)

        result = described_class.resolve_username('janedoe', sender_id, slack_client)
        expect(result).to eq({ user_id: another_user['id'] })
      end
    end

    context 'with nonexistent username' do
      it 'returns error' do
        allow(slack_client).to receive(:get_user_by_name).with('invalid').and_return(nil)

        result = described_class.resolve_username('invalid', sender_id, slack_client)
        expect(result).to eq({ error: 'User @invalid not found. Use exact username or <@userid> format.' })
      end
    end
  end

  describe '.validate_user' do
    context 'with valid user' do
      it 'returns user_id' do
        allow(slack_client).to receive(:get_user_by_id).with(another_user['id']).and_return(another_user)

        result = described_class.validate_user(another_user['id'], sender_id, slack_client)
        expect(result).to eq({ user_id: another_user['id'] })
      end
    end

    context 'with self-ping attempt' do
      it 'returns error' do
        allow(slack_client).to receive(:get_user_by_id).with(sender_id).and_return(active_user)

        result = described_class.validate_user(sender_id, sender_id, slack_client)
        expect(result).to eq({ error: 'You cannot ping yourself.' })
      end
    end

    context 'with bot user' do
      it 'returns error' do
        allow(slack_client).to receive(:get_user_by_id).with(bot_user['id']).and_return(bot_user)

        result = described_class.validate_user(bot_user['id'], sender_id, slack_client)
        expect(result).to eq({ error: 'You cannot ping bots or apps.' })
      end
    end

    context 'with deactivated user' do
      it 'returns error' do
        allow(slack_client).to receive(:get_user_by_id).with(deactivated_user['id']).and_return(deactivated_user)

        result = described_class.validate_user(deactivated_user['id'], sender_id, slack_client)
        expect(result).to eq({ error: 'Cannot ping deactivated users.' })
      end
    end

    context 'with nonexistent user ID (by_id: true)' do
      it 'returns error' do
        allow(slack_client).to receive(:get_user_by_id).with('UINVALID').and_return(nil)

        result = described_class.validate_user('UINVALID', sender_id, slack_client, by_id: true)
        expect(result).to eq({ error: 'User not found.' })
      end
    end
  end
end
