# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'

RSpec.describe 'Ping Command Endpoint', type: :integration do
  include Rack::Test::Methods

  def app
    require_relative '../../app'
    Sinatra::Application
  end

  let(:signing_secret) { ENV.fetch('SLACK_SIGNING_SECRET') }
  let(:sender_id) { "U#{Time.now.to_f.to_s.delete(".")}" }
  let(:target_user_id) { 'U456TARGET' }
  let(:channel_id) { 'C789CHANNEL' }
  let(:dm_channel_id) { 'D321DM' }
  let(:timestamp_val) { '1234567890.123456' }

  let(:params) do
    {
      token: 'test-token',
      team_id: 'T123',
      user_id: sender_id,
      channel_id: channel_id,
      text: '@targetuser',
      command: '/ping',
      response_url: 'https://hooks.slack.com/commands/123/456'
    }
  end

  describe 'POST /slack/commands' do
    context 'with invalid signature' do
      it 'returns 401' do
        header 'X-Slack-Request-Timestamp', Time.now.to_i.to_s
        header 'X-Slack-Signature', 'v0=invalid_signature'
        header 'Content-Type', 'application/x-www-form-urlencoded'

        post '/slack/commands', URI.encode_www_form(params)
        expect(last_response.status).to eq(401)
      end

      it 'returns error message' do
        header 'X-Slack-Request-Timestamp', Time.now.to_i.to_s
        header 'X-Slack-Signature', 'v0=invalid_signature'
        header 'Content-Type', 'application/x-www-form-urlencoded'

        post '/slack/commands', URI.encode_www_form(params)
        json = JSON.parse(last_response.body)
        expect(json['error']).to eq('Unauthorized')
      end
    end

    context 'with valid signature' do
      let(:body) { URI.encode_www_form(params) }
      let(:timestamp) { Time.now.to_i.to_s }

      before do
        sig_basestring = "v0:#{timestamp}:#{body}"
        signature = "v0=#{OpenSSL::HMAC.hexdigest("SHA256", signing_secret, sig_basestring)}"

        header 'X-Slack-Request-Timestamp', timestamp
        header 'X-Slack-Signature', signature
        header 'Content-Type', 'application/x-www-form-urlencoded'

        stub_request(:post, 'https://slack.com/api/users.list')
          .to_return(
            status: 200,
            body: { ok: true, members: [
              { 'id' => target_user_id, 'name' => 'targetuser', 'is_bot' => false, 'deleted' => false,
                'profile' => { 'display_name' => '', 'real_name' => 'Target User' } }
            ] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:post, 'https://slack.com/api/users.info')
          .with(body: hash_including('user' => target_user_id))
          .to_return(
            status: 200,
            body: { ok: true, user: { 'id' => target_user_id, 'name' => 'targetuser', 'is_bot' => false,
                                      'deleted' => false } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:post, 'https://slack.com/api/conversations.open')
          .with(body: hash_including('users' => target_user_id))
          .to_return(
            status: 200,
            body: { ok: true, channel: { 'id' => dm_channel_id } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:post, 'https://slack.com/api/chat.postMessage')
          .to_return(
            status: 200,
            body: { ok: true, ts: timestamp_val }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:post, 'https://slack.com/api/chat.delete')
          .to_return(
            status: 200,
            body: { ok: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns 200' do
        post '/slack/commands', body
        expect(last_response.status).to eq(200)
      end

      it 'returns JSON' do
        post '/slack/commands', body
        expect(last_response.content_type).to include('application/json')
      end

      it 'returns success message' do
        post '/slack/commands', body
        json = JSON.parse(last_response.body)
        expect(json['response_type']).to eq('ephemeral')
        expect(json['text']).to match(/Pinged <@#{target_user_id}>/)
      end
    end
  end
end
