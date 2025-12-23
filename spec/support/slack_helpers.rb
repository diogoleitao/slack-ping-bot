# frozen_string_literal: true

module SlackHelpers
  def stub_slack_users_list(members: nil)
    members ||= load_fixture('slack_responses')[:users_list_success][:members]

    stub_request(:post, 'https://slack.com/api/users.list')
      .to_return(
        status: 200,
        body: { ok: true, members: members, cache_ts: Time.now.to_i }.to_json,
        headers: { 'Content-Type' => 'application/json; charset=utf-8' }
      )
  end

  def stub_slack_users_info(user_id:, user: nil)
    user ||= load_fixture('users')[:active_user]

    stub_request(:post, 'https://slack.com/api/users.info')
      .with(body: hash_including('user' => user_id))
      .to_return(
        status: 200,
        body: { ok: true, user: user }.to_json,
        headers: { 'Content-Type' => 'application/json; charset=utf-8' }
      )
  end

  def stub_slack_chat_post_message(channel: 'D123456', timestamp: '1234567890.123456')
    stub_request(:post, 'https://slack.com/api/chat.postMessage')
      .to_return(
        status: 200,
        body: {
          ok: true,
          channel: channel,
          ts: timestamp,
          message: {
            type: 'message',
            text: '👋 Ping from <@U123456>',
            ts: timestamp
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json; charset=utf-8' }
      )
  end

  def stub_slack_chat_delete(channel: 'D123456', timestamp: '1234567890.123456')
    stub_request(:post, 'https://slack.com/api/chat.delete')
      .with(body: hash_including('channel' => channel, 'ts' => timestamp))
      .to_return(
        status: 200,
        body: { ok: true, channel: channel, ts: timestamp }.to_json,
        headers: { 'Content-Type' => 'application/json; charset=utf-8' }
      )
  end

  def stub_slack_conversations_open(user_id: 'U123456', channel_id: 'D123456')
    stub_request(:post, 'https://slack.com/api/conversations.open')
      .with(body: hash_including('users' => user_id))
      .to_return(
        status: 200,
        body: { ok: true, channel: { id: channel_id } }.to_json,
        headers: { 'Content-Type' => 'application/json; charset=utf-8' }
      )
  end

  def stub_slack_error(endpoint:, error:)
    stub_request(:post, "https://slack.com/api/#{endpoint}")
      .to_return(
        status: 200,
        body: { ok: false, error: error }.to_json,
        headers: { 'Content-Type' => 'application/json; charset=utf-8' }
      )
  end

  def generate_slack_signature(timestamp:, body:, secret: ENV.fetch('SLACK_SIGNING_SECRET', nil))
    sig_basestring = "v0:#{timestamp}:#{body}"
    "v0=#{OpenSSL::HMAC.hexdigest("SHA256", secret, sig_basestring)}"
  end
end
